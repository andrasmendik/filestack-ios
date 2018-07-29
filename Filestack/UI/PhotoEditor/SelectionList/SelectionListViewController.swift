//
//  SelectionListViewController.swift
//  EditImage
//
//  Created by Mihály Papp on 20/07/2018.
//  Copyright © 2018 Mihály Papp. All rights reserved.
//

import UIKit

protocol UploadListDelegate: class {
  func resignFromUpload()
  func uploadImages(_ images: UIImage)
}

class SelectionListViewController: UICollectionViewController {
  
  enum Mode {
    case edition
    case deletion
  }
  
  private var images: [UIImage]
  private var mode: Mode = .edition
  private var markedToDelete: Set<Int> = []
  private weak var delegate: UploadListDelegate?
  
  init(images: [UIImage], delegate: UploadListDelegate) {
    self.images = images
    self.delegate = delegate
    super.init(collectionViewLayout: UICollectionViewFlowLayout())
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    collectionView?.register(SelectionCell.self)
    collectionView?.backgroundColor = .white
  }
}

// MARK: CollectionView User Triggered Events
extension SelectionListViewController {
  var numberOfCells: Int {
    return images.count
  }
  
  func cellWasPressed(on row: Int) {
    switch mode {
    case .edition: edition(with: row)
    case .deletion: deletion(with: row)
    }
  }
  
  func cellWasLongPressed(on row: Int) {
    switch mode {
    case .deletion: break
    case .edition: startDeleteMode()
    }
    deletion(with: row)
  }

  func cellWasDisplayed(_ cell: SelectionCell, on row: Int) {
    cell.imageView.image = images[row]
    switch mode {
    case .edition:
      cell.mode = .standard
      print("row: \(row) .standard")
    case .deletion:
      cell.mode = .deletion(markedToDelete: isMarketToDelete(row))
      print("row: \(row) .deletion(\(isMarketToDelete(row)))")

    }
  }
}

// MARK: ViewSetup
private extension SelectionListViewController {
  func setup() {
    navigationItem.leftBarButtonItem = cancelItem
    navigationItem.rightBarButtonItem = uploadItem
  }
  
  var cancelItem: UIBarButtonItem {
    return UIBarButtonItem(barButtonSystemItem: .cancel,
                           target: self,
                           action: #selector(cancelButtonPressed))
  }
  
  var deleteItem: UIBarButtonItem {
    let item = UIBarButtonItem(barButtonSystemItem: .trash,
                               target: self,
                               action: #selector(deleteButtonPressed))
    item.tintColor = .red
    item.isEnabled = false
    return item
  }
  
  var uploadItem: UIBarButtonItem {
    return UIBarButtonItem(image: UIImage(named: "icon-upload", in: Bundle(for: type(of: self)), compatibleWith: nil),
                                          style: .plain,
                                          target: self,
                                          action: #selector(uploadButtonPressed))
  }
  
  @objc func uploadButtonPressed() {
    //TODO: upload
  }
  
  @objc func deleteButtonPressed() {
    deleteAndRefresh()
  }
  
  @objc func cancelButtonPressed() {
    switch mode {
    case .edition: dismissAll()
    case .deletion: stopDeleteMode()
    }
  }
}

private extension SelectionListViewController {
  func dismissAll() {
    dismiss(animated: true) {
      self.delegate?.resignFromUpload()
    }
  }
}

private extension SelectionListViewController {
  func stopDeleteMode() {
    mode = .edition
    navigationItem.rightBarButtonItem = uploadItem
    markedToDelete = []
    updateAllVisibleCells()
  }

  func startDeleteMode() {
    mode = .deletion
    navigationItem.rightBarButtonItem = deleteItem
    allSelectionCells.forEach { (cell) in
      cell.mode = .deletion(markedToDelete: false)
    }
  }
  
  func deleteAndRefresh() {
    deleteSelected()
    UIView.animate(withDuration: 0.5, animations: {
      self.visibleCellsToDelete().forEach({ (cell) in
        cell.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
      })
    }, completion: { _ in
      self.stopDeleteMode()
      self.collectionView?.reloadData()
    })
  }
  
  func deleteSelected() {
    images = images.enumerated().filter { (index, _) -> Bool in
      !markedToDelete.contains(index)
      }.map { (_, image) -> UIImage in
        return image
      }
  }
}

private extension SelectionListViewController {
  func edition(with row: Int) {
    let image = images[row]
//    let editor = EditorViewController(image: image) { editedImage in
//      self.images[row] = editedImage
//      self.collectionView?.reloadData()
//    }
//    present(editor, animated: true)
  }
  
  func deletion(with row: Int) {
    if isMarketToDelete(row) {
      removeFromMarkedToDelete(row)
    } else {
      addToMarkedToDelete(row)
    }
    navigationItem.rightBarButtonItem?.isEnabled = markedToDelete.count > 0
  }
  
  func isMarketToDelete(_ row: Int) -> Bool {
    return markedToDelete.contains(row)
  }
  
  func addToMarkedToDelete(_ row: Int) {
    markedToDelete.insert(row)
    let cell = collectionView?.cellForItem(at: IndexPath(row: row, section: 0)) as? SelectionCell
    setMode(for: cell)
  }
  
  func removeFromMarkedToDelete(_ row: Int) {
    markedToDelete.remove(row)
    let cell = collectionView?.cellForItem(at: IndexPath(row: row, section: 0)) as? SelectionCell
    setMode(for: cell)
  }
  
  func setMode(for cell: SelectionCell?) {
    guard let cell = cell, let indexPath = collectionView?.indexPath(for: cell) else { return }
    switch mode {
    case .edition: cell.mode = .standard
    case .deletion: cell.mode = .deletion(markedToDelete: isMarketToDelete(indexPath.row))
    }
  }
}

extension SelectionListViewController {
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    updateAllVisibleCells()
  }
  
  func updateAllVisibleCells() {
    allSelectionCells.forEach { self.setMode(for: $0) }
  }
  
  func visibleCellsToDelete() -> [SelectionCell] {
    guard let collectionView = collectionView else {
      return []
    }
    return allSelectionCells.filter { (cell) -> Bool in
      if let index = collectionView.indexPath(for: cell) {
        return markedToDelete.contains(index.row)
      }
      return false
    }
  }

  var allSelectionCells: [SelectionCell] {
    return collectionView?.visibleCells as? [SelectionCell] ?? []
  }
}