//
//  CollectionViewModel.swift
//  IIIF Presenter
//
//  Created by Jakub Fiser on 13/02/2017.
//  Copyright © 2017 Jakub Fiser. All rights reserved.
//

import Foundation

class CollectionViewModel {
    
    var collection: IIIFCollection
    var delegate: CardListDelegate?
    
    var manifestCount: Int {
        return collection.manifests.count
    }
    
    static func createWithUrl(_ url: String, _ delegate: CardListDelegate?) -> CollectionViewModel {
        return CollectionViewModel(url, delegate)
    }
    
    init(_ collection: IIIFCollection) {
        self.collection = collection
    }
    
    fileprivate init(_ urlString: String, _ delegate: CardListDelegate?) {
        collection = IIIFCollection.createCollectionWith([])
        self.delegate = delegate
        if let url = URL(string: urlString) {
            delegate?.didStartLoadingData()
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if data != nil,
                    let serialization = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) {
                    if let c = IIIFCollection(serialization as! [String:Any]) {
                        self.collection = c
                    } else if let m = IIIFManifest(serialization as! [String:Any]) {
                        self.collection.manifests.insert(m, at: 0)
                    }
                }
                
                DispatchQueue.main.async {
                    self.delegate?.didFinishLoadingData()
                }
            }).resume()
        }
    }
    
    func getManifestAtPosition(_ i: Int) -> IIIFManifest {
        return collection.manifests[i]
    }
    
    func selectManifestAt(_ index: Int) {
        let manifest = getManifestAtPosition(index)
        delegate?.showViewer(manifest: manifest)
    }
    
    func deleteManifestAt(_ index: Int) {
        collection.manifests.remove(at: index)
    }
}
