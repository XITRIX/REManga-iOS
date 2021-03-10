//
//  ReClient.swift
//  REManga
//
//  Created by Daniil Vinogradov on 21.02.2021.
//

import Alamofire
import Foundation

class ReClient {
    static let baseUrl = "https://api.remanga.org/"
    
    static let shared = ReClient()
    
    @discardableResult
    func getTitle(title: String, completionHandler: @escaping (Result<ReTitleModel, Error>) -> ()) -> DataRequest? {
        let api = "api/titles/" + title
        return baseRequest(api, completionHandler: completionHandler)
    }
    
    @discardableResult
    func getBranch(branch: Int, completionHandler: @escaping (Result<ReBranchModel, Error>) -> ()) -> DataRequest? {
        let api = "api/titles/chapters/?branch_id=" + String(branch)
        return baseRequest(api, completionHandler: completionHandler)
    }
    
    @discardableResult
    func getSimilar(title: String, completionHandler: @escaping (Result<ReSimilarModel, Error>) -> ()) -> DataRequest? {
        let api = "api/titles/" + title + "/similar"
        return baseRequest(api, completionHandler: completionHandler)
    }
    
    @discardableResult
    func getChapter(chapter: Int, completionHandler: @escaping (Result<ReChapterModel, Error>) -> ()) -> DataRequest? {
        let api = "api/titles/chapters/\(chapter)/"
        return baseRequest(api, completionHandler: completionHandler)
    }
    
    @discardableResult
    func getCatalog(page: Int, count: Int = 30, completionHandler: @escaping (Result<ReCatalogModel, Error>) -> ()) -> DataRequest? {
        let api = "api/search/catalog/?ordering=-rating&page=\(page)&count=\(count)"
        return baseRequest(api, completionHandler: completionHandler)
    }
    
    @discardableResult
    func getSearch(query: String, page: Int, count: Int = 30, completionHandler: @escaping (Result<ReSearchModel, Error>) -> ()) -> DataRequest? {
        let api = "api/search/?query=\(query)&page=\(page)&count=\(count)"
        return baseRequest(api, completionHandler: completionHandler)
    }
    
    @discardableResult
    func baseRequest<T: Decodable>(_ api: String, completionHandler: @escaping (Result<T, Error>) -> ()) -> DataRequest? {
        guard let apiUrl = api.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            completionHandler(.failure(RuntimeError("Wrong url: \(api)")))
            return nil
        }
        
        return AF.request(ReClient.baseUrl + apiUrl, method: .get, encoding: URLEncoding.default).responseData { response in
            switch response.result {
            case .success(let res):
                do {
                    let title = try JSONDecoder().decode(T.self, from: res)
                    completionHandler(.success(title))
                    print(title)
                } catch {
                    completionHandler(.failure(error))
                    print(error)
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}
