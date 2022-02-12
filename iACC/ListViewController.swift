//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

// Strategy Pattern , a single interface for many strategies
protocol ItemsService {
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void)
}



// Adapter pattern allows us to keep our different service implementations independent of the ItemsService
// Use the Adapter pattern to keep low-level components and high-level components independent of eachother
class ListViewController: UITableViewController {
    var items = [ItemViewModel]()
    
    var service: ItemsService?
    
    var retryCount = 0
    var maxRetryCount = 0
    var shouldRetry = false

    var longDateStyle = false

    var fromReceivedTransfersScreen = false
    var fromSentTransfersScreen = false
    var fromCardsScreen = false
    var fromFriendsScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if tableView.numberOfRows(inSection: 0) == 0 {
            refresh()
        }
    }
    
    @objc private func refresh() {
        refreshControl?.beginRefreshing()
        service?.loadItems(completion: handleAPIResult)
    }
    
    private func handleAPIResult(_ result: Result<[ItemViewModel], Error>) {
        switch result {
        case let .success(items):
            self.retryCount = 0
            self.items = items
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            
        case let .failure(error):
            if shouldRetry && retryCount < maxRetryCount {
                retryCount += 1
                refresh()
                return
            }
            
            retryCount = 0
            
            if fromFriendsScreen && User.shared?.isPremium == true {
                (UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache.loadFriends { [weak self] result in
                    DispatchQueue.mainAsyncIfNeeded {
                        switch result {
                        case let .success(items):
                            self?.items = items.map { item in
                                ItemViewModel(friend: item) { [weak self] in
                                    self?.select(friend: item)
                                }
                            }
                            self?.tableView.reloadData()
                            
                        case let .failure(error):
                            self?.showError(error: error)
                        }
                        self?.refreshControl?.endRefreshing()
                    }
                }
            } else {
                self.showError(error: error)
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    // cell is dependent on ItemViewModel
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ItemCell")
        cell.configure(item)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.select()
    }
}
