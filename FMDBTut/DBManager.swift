//
//  DBManager.swift
//  FMDBTut
//
//  Created by Engin KUK on 4.12.2020.
//  Copyright © 2020 Appcoda. All rights reserved.
//

import UIKit

class DBManager: NSObject {

    static let shared: DBManager = DBManager()
    let databaseFileName = "database.sqlite"
    var pathToDatabase: String!
    var database: FMDatabase!
    
    let field_MovieID = "movieID"
    let field_MovieTitle = "title"
    let field_MovieCategory = "category"
    let field_MovieYear = "year"
    let field_MovieURL = "movieURL"
    let field_MovieCoverURL = "coverURL"
    let field_MovieWatched = "watched"
    let field_MovieLikes = "likes"
    
    override init() {
        super.init()
     
        let documentsDirectory = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String
        pathToDatabase = documentsDirectory.appending("/\(databaseFileName)")
    }
    
    func createDatabase() -> Bool {
        var created = false
        // if no path exists create the db
        if !FileManager.default.fileExists(atPath: pathToDatabase) {
            database = FMDatabase(path: pathToDatabase!)
            
            if database != nil {
                // Open the database.
                if database.open() {
                    let createMoviesTableQuery = "create table movies (\(field_MovieID) integer primary key autoincrement not null, \(field_MovieTitle) text not null, \(field_MovieCategory) text not null, \(field_MovieYear) integer not null, \(field_MovieURL) text, \(field_MovieCoverURL) text not null, \(field_MovieWatched) bool not null default 0, \(field_MovieLikes) integer not null)"
                    
                    do {
                        try database.executeUpdate(createMoviesTableQuery, values: nil)
                        created = true
                    }
                    catch {
                        print("Could not create table.")
                        print(error.localizedDescription)
                    }
                    
                    database.close()
                }
                else {
                    print("Could not open the database.")
                }
            }
        }
        return created
    }
    
    func openDatabase() -> Bool {
        if database == nil {
            if FileManager.default.fileExists(atPath: pathToDatabase) {
            database = FMDatabase(path: pathToDatabase!)   //this creates the database if it doesnt exists
            // No connection is being established at that point though. We just know that after that line we can use the database property to have access to our database.
            }
        }
        
            if database != nil {
                if database.open() {
                    return true
                } else {
                    print("Could not open the database.")
                }
            }
            return false
    }
    
 
    func insertMovieData() {
        if openDatabase() {
            // get the path of the “movies.tsv”
            if let pathToMoviesFile = Bundle.main.path(forResource: "movies", ofType: "tsv") {
                // Creating a string with the contents of file can throw an exception, so using the do-catch statement is necessary.
                do {
                    let moviesFileContents = try String(contentsOfFile: pathToMoviesFile)
                    // break the contents of the string into an array of strings based on the “\r\n” characters:
                    let moviesData = moviesFileContents.components(separatedBy: "\r\n")
     
                    var query = ""
                    for movie in moviesData {
                        let movieParts = movie.components(separatedBy: "\t")
     
                        if movieParts.count == 5 {
                            let movieTitle = movieParts[0]
                            let movieCategory = movieParts[1]
                            let movieYear = movieParts[2]
                            let movieURL = movieParts[3]
                            let movieCoverURL = movieParts[4]
                            // We want to execute multiple queries at once, and SQLite will manage to distinguish them based on the ; symbol
                            query += "insert into movies (\(field_MovieID), \(field_MovieTitle), \(field_MovieCategory), \(field_MovieYear), \(field_MovieURL), \(field_MovieCoverURL), \(field_MovieWatched), \(field_MovieLikes)) values (null, '\(movieTitle)', '\(movieCategory)', \(movieYear), '\(movieURL)', '\(movieCoverURL)', 0, 0);"
                        }
                    }
     
                    if !database.executeStatements(query) {
                        print("Failed to insert initial data into the database.")
                        print(database.lastError(), database.lastErrorMessage())
                    }
                }
                catch {
                    print(error.localizedDescription)
                }
            }
     
            database.close()
        }
    }
    
    func loadMovies() -> [MovieInfo]! {
        var movies: [MovieInfo]!
        
        if openDatabase() {
            // create the SQL query that tells the database which data to load:
            let query = "select * from movies order by \(field_MovieYear) asc"
            // we’re just asking from FMDB to fetch all the movies ordered in an ascending order based on the release year.
            do {
                print(database)
                let results = try database.executeQuery(query, values: nil)
                // The results.next() method should be always called.for single methods call if statement instead of while
                while results.next() {
                    let movie = MovieInfo(movieID: Int(results.int(forColumn: field_MovieID)),
                                          title: results.string(forColumn: field_MovieTitle),
                                          category: results.string(forColumn: field_MovieCategory),
                                          year: Int(results.int(forColumn: field_MovieYear)),
                                          movieURL: results.string(forColumn: field_MovieURL),
                                          coverURL: results.string(forColumn: field_MovieCoverURL),
                                          watched: results.bool(forColumn: field_MovieWatched),
                                          likes: Int(results.int(forColumn: field_MovieLikes))
                    )
                 
                    if movies == nil {
                        movies = [MovieInfo]()
                    }
                 
                    movies.append(movie)
                }
            }
            catch {
                print(error.localizedDescription)
            }
            database.close()
        }
     
        return movies
    }
    
    // you can use completion handlers instead of return values when fetching data from the database.
    
    func loadMovie(withID ID: Int, completionHandler: (_ movieInfo: MovieInfo?) -> Void) {
        var movieInfo: MovieInfo!
     
        if openDatabase() {
            // this query loads according to ID of the movie
            let query = "select * from movies where \(field_MovieID)=?"
     
            do {
                let results = try database.executeQuery(query, values: [ID])
     
                if results.next() {
                    movieInfo = MovieInfo(movieID: Int(results.int(forColumn: field_MovieID)),
                                          title: results.string(forColumn: field_MovieTitle),
                                          category: results.string(forColumn: field_MovieCategory),
                                          year: Int(results.int(forColumn: field_MovieYear)),
                                          movieURL: results.string(forColumn: field_MovieURL),
                                          coverURL: results.string(forColumn: field_MovieCoverURL),
                                          watched: results.bool(forColumn: field_MovieWatched),
                                          likes: Int(results.int(forColumn: field_MovieLikes))
                    )
     
                }
                else {
                    print(database.lastError())
                }
            }
            catch {
                print(error.localizedDescription)
            }
     
            database.close()
        }
     
        completionHandler(movieInfo)
    }
     
    func updateMovie(withID ID: Int, watched: Bool, likes: Int) {
        if openDatabase() {
            let query = "update movies set \(field_MovieWatched)=?, \(field_MovieLikes)=? where \(field_MovieID)=?"
     
            do {
                // This method is the one that you have to use to perform any kind of changes to the database create or update
                // The second parameter of that method is again an array of Any objects that you pass along with the query that will be executed.
                try database.executeUpdate(query, values: [watched, likes, ID])
                // we could return a bool value to indicate if db is updated.
            }
            catch {
                print(error.localizedDescription)
            }
     
            database.close()
        }
    }
     
    func deleteMovie(withID ID: Int) -> Bool {
        var deleted = false
     
        if openDatabase() {
            let query = "delete from movies where \(field_MovieID)=?"
     
            do {
                try database.executeUpdate(query, values: [ID])
                deleted = true
            }
            catch {
                print(error.localizedDescription)
            }
     
            database.close()
        }
     
        return deleted
    }
    
    
}

// more advanced query:
// let query = "select * from movies where \(field_MovieCategory)=? order by \(field_MovieYear) desc"
// let results = try database.executeQuery(query, values: ["Crime"])

// Another example, where we load all the movies data for a specific category and release year greater than the year that we’ll specify, ordered by their ID values in a descending order:
// let query = "select * from movies where \(field_MovieCategory)=? and \(field_MovieYear)>? order by \(field_MovieID) desc"
// let results = try database.executeQuery(query, values: ["Crime", 1990])

// We started the demo app by creating the database programmatically, but that’s not the only way to do it. You can create your database using an SQLite manager and specify the tables and their fields in an easy and graphical way, and then put the database file in your application bundle. However, you’ll have to copy it to the documents directory if you’re planning to make changes through the app into the database.

