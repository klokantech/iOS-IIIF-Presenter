//
//  CardListController.swift
//  IIIF Presenter
//
//  Created by Jakub Fiser on 02/02/2017.
//  Copyright © 2017 Jakub Fiser. All rights reserved.
//

import UIKit

class CardListController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var messageView: UIView?
    @IBOutlet weak var messageIcon: UIImageView?
    @IBOutlet weak var messageLabel: UILabel?
    
    fileprivate let manifestViewer = "ManifestViewer"
    fileprivate let sectionInsets = UIEdgeInsets(top: 6.0, left: 6.0, bottom: 6.0, right: 6.0)
    fileprivate var isLoading: Bool = false
    
    var showFirstError = false
    var viewModel: CollectionViewModel? {
        willSet {
            viewModel?.delegate = nil
        }
        didSet {
            viewModel?.delegate = self
            collectionView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isLoading {
            spinner?.startAnimating()
        }
        collectionView.backgroundColor = UIColor.clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // redo all url requests (using cache for already completed ones)
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // cancel all ongoing url requests
        for cell in collectionView.visibleCells as! [CardCell] {
            cell.viewModel = nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? ViewerController {
            controller.viewModel = ManifestViewModel(sender as! IIIFManifest)
        } else if let controller = segue.destination as? CardListController {
            controller.viewModel = CollectionViewModel(sender as! IIIFCollection)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func deleteCell(_ cell: CardCell) {
        if let index = collectionView.indexPath(for: cell) {
            viewModel?.deleteItemAt(index.item)
            collectionView.deleteItems(at: [index])
            if index.item == 0 && showFirstError {
                showFirstError = false
                showAlert("Can't open specified URL.")
            }
        }
    }
    
    fileprivate func showAlert(_ msg: String?="An error occured") {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func handleSectionNumber(_ number: Int) {
        if let error = viewModel?.loadingError {
            messageView?.isHidden = false
            messageLabel?.text = "\(error.code): \(error.localizedDescription)"
        } else if messageView != nil && !messageView!.isHidden {
            messageView?.isHidden = true
        }
    }
    
    func replaceItem(cell: UICollectionViewCell, item: Any) {
        if let index = collectionView.indexPath(for: cell) {
            viewModel?.replaceItem(item, at: index.item)
        }
    }
}


extension CardListController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let number = viewModel != nil ? 1 : 0
        handleSectionNumber(number)
        return number
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel!.itemsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CardCell.reuseId, for: indexPath) as! CardCell
        
        let item = viewModel!.getItemAtPosition(indexPath.item)
        cell.collection = self
        cell.viewModel = CardViewModel.getModel(item, delegate: cell)
        
        return cell
    }
}


extension CardListController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CardCell
        if !cell.viewModel!.isLoadingData {
            viewModel?.selectItemAt(indexPath.item)
        }
    }
}


extension CardListController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow = CGFloat(Constants.cardsPerRow + (view.frame.width > view.frame.height ? 1 : 0))
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = (availableWidth / itemsPerRow) - 1
        let aspectRatio: CGFloat = 4/9
        return CGSize(width: widthPerItem, height: widthPerItem * aspectRatio)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

extension CardListController: CardListDelegate {
    
    func showViewer(manifest: IIIFManifest) {
        performSegue(withIdentifier: manifestViewer, sender: manifest)
    }
    
    func showCollection(collection: IIIFCollection) {
        let controller = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "cardListController") as! CardListController
        controller.viewModel = CollectionViewModel.createWithUrl(collection.id.absoluteString, delegate: controller)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func didStartLoadingData() {
        isLoading = true
        spinner?.startAnimating()
    }
    
    func didFinishLoadingData(error: NSError?) {
        isLoading = false
        spinner?.stopAnimating()
        collectionView.reloadData()
    }
}
