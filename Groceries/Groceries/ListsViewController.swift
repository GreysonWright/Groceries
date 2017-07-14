//
//  ListsViewController.swift
//  Groceries
//
//  Created by Greyson Wright on 6/12/17.
//  Copyright © 2017 Greyson Wright. All rights reserved.
//

import UIKit

fileprivate enum ListsViewControllerMode {
	case normal
	case selectList
}

class ListsViewController: BaseViewController {
	@IBOutlet weak var newListButton: UIButton!
	fileprivate var selectionCompleted: ((Bool) -> (Void))?
	fileprivate var newInentory: [InventoryItem]?
	fileprivate var mode: ListsViewControllerMode {
		if newInentory == nil {
			return .normal
		}
		return .selectList
	}
	
	convenience init(with title: String?) {
		self.init(nibName: "ListsViewController", bundle: nil)
		self.title = title
	}
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
		cellNibName = "ListTableViewCell"
		reuseIdentifier = "ListCell"
		
		loadListsIntoTableView()
	}
	
	fileprivate func loadListsIntoTableView() {
		let lists = getListsFromRealm()
		let section = buildSection(with: lists)
		sections.removeAll()
		sections.append(section)
	}
	
	fileprivate func getListsFromRealm() -> [ItemList] {
		guard let manager = try? RealmManager(fileNamed: RealmManager.listsRealm) else {
			print("Couldn't find lists realm.")
			return []
		}
		let listInventory = manager.getAllObjects(ItemList.self)
		return Array(listInventory)
	}

	fileprivate func buildSection(with lists: [ItemList]) -> TableViewSection {
		let section = TableViewSection(with: nil, rowData: lists)
		section.collapsed = false
		section.collapsible = false
		return section
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	func addToUserDefinedList(inventory: [InventoryItem], target: UIViewController, navigationController: UINavigationController?, completed: ((Bool) -> Void)?) {
		newInentory = inventory
		guard let navigationController = navigationController else {
			target.present(self, animated: true, completion: nil)
			return
		}
		navigationController.viewControllers.append(self)
		target.present(navigationController, animated: true, completion: nil)
		selectionCompleted = completed
	}
}

//MARK: -UIButton
extension ListsViewController {
	@IBAction func newListButtonTapped(_ sender: Any) {
		let newListAlertController = UIAlertController(title: "New List", message: nil, preferredStyle: .alert)
		newListAlertController.addTextField { (textField: UITextField) in
			textField.placeholder = "List Name"
		}
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		newListAlertController.addAction(cancelAction)
		let createListAction = UIAlertAction(title: "Create", style: .default) { (action: UIAlertAction) in
			self.createListActionTapped(alertAction: action, controller: newListAlertController)
		}
		newListAlertController.addAction(createListAction)
		present(newListAlertController, animated: true, completion: nil)
	}
	
	fileprivate func createListActionTapped(alertAction: UIAlertAction, controller alertController: UIAlertController) {
		guard let listTitle = alertController.textFields![0].text else {
			return
		}
		let newList = buildNewList(with: listTitle)
		write(newList, to: RealmManager.listsRealm)
		loadListsIntoTableView()
		tableView.reloadData()
	}
	
	fileprivate func buildNewList(with title: String) -> ItemList {
		let newList = ItemList()
		newList.title = title
		return newList
	}
	
	fileprivate func write(_ list: ItemList, to realmName: String) {
		do {
			let manager = try RealmManager(fileNamed: realmName)
			try manager.add(list)
		} catch {
			print("Couldn't create new list.")
		}
	}
}

// MARK: - UITableView
extension ListsViewController {
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 48
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let row = sections[indexPath.section].rows[indexPath.row]
		let rowData = row.data as! ItemList
		
		let cell = super.tableView(tableView, cellForRowAt: indexPath) as! ListTableViewCell
		cell.titleTextLabel.text = rowData.title
		cell.priceTextLabel.text = String(format: "$%.2lf", rowData.totalPrice)
		return cell
	}
	
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let row = sections[indexPath.section].rows[indexPath.row]
		let rowData = row.data as! ItemList
		if mode == .normal {
			pushToSelectViewController(with: rowData, at: indexPath)
		} else {
			writeUpdate(for: rowData, to: RealmManager.listsRealm)
			dismiss(animated: true, completion: nil)
		}
		tableView.deselectRow(at: indexPath, animated: true)
		selectionCompleted?(true)
	}
	
	func pushToSelectViewController(with rowData: ItemList, at indexPath: IndexPath) {
		let listInventoryViewController = SelectItemViewController(with: rowData.title, listItems: Array(rowData.inventory))
		navigationController?.pushViewController(listInventoryViewController, animated: true)
	}
	
	fileprivate func writeUpdate(for itemList: ItemList, to realmName: String) {
		do {
			let manager = try RealmManager(fileNamed: realmName)
			try manager.update {
				newInentory?.forEach({ (item: InventoryItem) in
					item.listTitle = itemList.title
					item.key = item.builtKey
					itemList.inventory.append(item)
				})
			}
		} catch {
			print("Could not update object.")
		}
	}
}
