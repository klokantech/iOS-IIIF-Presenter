//
//  ViewerController.swift
//  IIIF Presenter
//
//  Created by Jakub Fiser on 20/02/2017.
//  Copyright © 2017 Jakub Fiser. All rights reserved.
//

import UIKit
import iOSTiledViewer

class ViewerController: UIViewController {

    fileprivate let manifestDetail = "ManifestDetail"
    
    @IBOutlet weak var collection: UICollectionView!
    
    var viewModel: ManifestViewModel? {
        didSet {
            collection?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let info = UIButton(type: .infoLight)
        info.addTarget(self, action: #selector(showInfo), for: .primaryActionTriggered)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: info)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        collection.collectionViewLayout.invalidateLayout()
    }
    
    @IBAction func showInfo() {
        performSegue(withIdentifier: manifestDetail, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? ManifestController {
            controller.viewModel = viewModel
        }
    }
}


extension ViewerController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let number = viewModel?.manifest.sequences?.count
        return number != nil ? number! : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel!.manifest.sequences![section].canvases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ViewerCell.reuseId, for: indexPath) as! ViewerCell
        
        let canvas = viewModel!.manifest.sequences![indexPath.section].canvases[indexPath.item]
        cell.viewModel = CanvasViewModel(canvas)
        
        return cell
    }
}


extension ViewerController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}
