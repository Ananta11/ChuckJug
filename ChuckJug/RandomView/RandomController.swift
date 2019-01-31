//
//  RandomController.swift
//  ChuckJug
//
//  Created by Ananta Shahane on 31/01/19.
//  Copyright © 2019 Ananta Shahane. All rights reserved.
//

import UIKit
import CoreData

class RandomController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var resultsController : NSFetchedResultsController<JokeData>!
    var context : NSManagedObjectContext!
    var refresher : UIRefreshControl!
    
    struct Joke : Codable {
        let category : [String]?
        let icon_url : URL
        let id : String
        let url : URL
        let value : String
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
        
        SetResultsController()
        SetupUI()
        
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.resultsController.fetchedObjects?.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RandomCell
        let cellData = self.resultsController.fetchedObjects?[indexPath.row]
        if let cellData = cellData {
            cell.SetupCell(for: cellData)
        }
        cell.delegate = self
        return cell
    }
    
    @objc func GetJoke() {
        guard let url = URL(string: "https://api.chucknorris.io/jokes/random") else { return }
        
        URLSession.shared.dataTask(with: url) {(data, response, error) in
            if let error = error {
                print( "Fetch error: \(error.localizedDescription) \n Response type: \(String(describing: response))")
                return
            }
            if let data = data {
                let decoder = JSONDecoder()
                do {
                    let parsedData = try decoder.decode(Joke.self, from: data)
                    let newJoke = NSEntityDescription.insertNewObject(forEntityName: "JokeData", into: self.context)
                    newJoke.setValue(parsedData.id, forKey: "jokeid")
                    newJoke.setValue(parsedData.value, forKey: "joke")
                    newJoke.setValue(parsedData.category, forKey: "category")
                    newJoke.setValue(false, forKey: "favourite")
                    newJoke.setValue(Date.init(timeIntervalSinceNow: 0), forKey: "added")
                    try self.context.save()
                }
                catch let err {
                    print("Decoding/Saving error: \(err.localizedDescription)")
                    return
                }
            }
        }.resume()
        refresher.endRefreshing()
    }
    
    func SetupUI() {
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(RandomController.GetJoke), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(refresher)
    }
    
    func SetResultsController() {
        let fetchRequest = NSFetchRequest<JokeData>(entityName: "JokeData")
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "added", ascending: false)]
        
        self.resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try self.resultsController.performFetch()
        }
            
        catch let err {
            print("Fetch error: \(err.localizedDescription)")
            return
        }
        self.resultsController.delegate = self
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case NSFetchedResultsChangeType.insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case NSFetchedResultsChangeType.delete:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
            break
        case NSFetchedResultsChangeType.move:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case NSFetchedResultsChangeType.update:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        default:
            break
        }
    }
}

extension RandomController : JokeCellDelegate {
    func didClickedFavourite(for Joke: JokeData) {
        for object in self.resultsController.fetchedObjects! {
            if object.jokeid == Joke.jokeid {
                object.favourite = Joke.favourite
                do {
                    try self.context.save()
                }
                catch let err{
                    print("Error saving: \(err)")
                }
                
            }
        }
    }
    
    func didClickedAction(for Joke: String) {
        let Share = UIActivityViewController(activityItems: [Joke], applicationActivities: nil)
        Share.popoverPresentationController?.sourceView = self.view
        self.present(Share, animated: true, completion: nil)
    }
    
    
}
