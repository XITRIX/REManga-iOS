//
//  ReaderViewModel.swift
//  REManga
//
//  Created by Daniil Vinogradov on 07.03.2021.
//

import Bond
import Foundation

struct ReaderBookmarkState {
    var props: [ReTitleStatus]
    var current: Int?
}

struct ReaderViewModelParams {
    var chapterId: Int
    var chapters: [ReBranchContent]?
}

class ReaderViewModel: BaseViewModelWith<ReaderViewModelParams> {
    var id: Int = 0
    let name = Observable<String?>(nil)
    let score = Observable<String?>(nil)
    let pages = MutableObservableCollection<[ReChapterPage]>()
    let rated = Observable<Bool>(false)
    
    var chapters: [ReBranchContent]?
    var currentChapter: Int = 0
    
    let prevAvailable = Observable<Bool>(false)
    let nextAvailable = Observable<Bool>(false)
    
    private(set) var parameters: ReaderViewModelParams!

    override func prepare(_ params: ReaderViewModelParams) {
        chapters = params.chapters
        id = params.chapterId
        
        loadChapter { result in
            switch result {
            case .failure(let error):
                self.setState(.failed(error))
            case .success(let model):
                self.setState(.done)
                
                if let branch = model.content.branchID {
                    self.loadChapters(branch: branch)
                }
            }
        }
    }
    
    public func loadPrevChapter() {
        guard let chapters = chapters
        else { return }
        
        ReClient.shared.setViews(chapter: chapters[currentChapter].id)
        currentChapter += 1
        id = chapters[currentChapter].id
        loadChapter()
    }
    
    public func loadNextChapter() {
        guard let chapters = chapters
        else { return }
        
        ReClient.shared.setViews(chapter: chapters[currentChapter].id)
        currentChapter -= 1
        id = chapters[currentChapter].id
        loadChapter()
    }
    
    private func loadChapters(branch: Int) {
        getCurrentChapter()
        if chapters == nil {
            ReClient.shared.getBranch(branch: branch) { result in
                switch result {
                case .success(let model):
                    self.chapters = model.content
                    self.getCurrentChapter()
                case .failure(_):
                    break
                }
            }
        }
    }
    
    private func getCurrentChapter() {
        guard let chapters = chapters
        else { return }
        
        if let chapter = chapters.enumerated().first(where: { $0.element.id == self.id })?.offset {
            currentChapter = chapter
        }
        
        updateStates()
    }
    
    private func loadChapter(completionHandler: ((Result<ReChapterModel, Error>) -> ())? = nil) {
        if let chapters = chapters {
            name.value = "Глава \(chapters[currentChapter].chapter.text)"
        }
        
        updateStates()
        pages.removeAll()
        ReClient.shared.getChapter(chapter: id) { result in
            switch result {
            case .failure(let error):
                self.setState(.failed(error))
                completionHandler?(.failure(error))
            case .success(let model):
                self.setState(.done)
                self.loadModel(model.content)
                completionHandler?(.success(model))
            }
        }
    }

    private func loadModel(_ model: ReChapterContent) {
        name.value = "Глава \(model.chapter.text)"
        score.value = model.score.text
        rated.value = model.rated ?? false
        pages.replace(with: model.pages.map {
            $0.parts
        }.flatMap {
            $0
        })
    }
    
    private func updateStates() {
        guard let chapters = chapters
        else { return }
        
        prevAvailable.value = chapters.count - 1 > currentChapter
        nextAvailable.value = currentChapter > 0
    }
}
