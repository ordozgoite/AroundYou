//
//  HTTPClient.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

protocol HTTPClient {
    func sendRequest<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async -> Result<T, RequestError>
//    func upload<T: Decodable>(file: Data, endpoint: Endpoint, responseModel: T.Type) async -> Result<T, RequestError>
//    func upload(file: Data)
}

extension HTTPClient {
    
    //MARK: - Send Request
    
    func sendRequest<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async -> Result<T, RequestError> {
        
        guard var urlComponents = URLComponents(url: endpoint.baseUrl.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            return .failure(.invalidURL)
        }
        
//        if let query = endpoint.query {
//            urlComponents.queryItems = query.map { URLQueryItem(name: $0.key, value: ($0.value as! String)) }
//        }
        
        if let query = endpoint.query {
            urlComponents.queryItems = query.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
        }
        
//        urlComponents.queryItems = endpoint.query?.map({ (key: String, value: Any) in
//            return URLQueryItem(name: key, value: value as? String)
//        })
        
        guard let url = urlComponents.url else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header
        
        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        }
        
        do {
            
#if DEBUG
            print("➡️ URL: \(request.url!)")
            print("➡️ body: \(String(decoding: request.httpBody ?? Data(), as: UTF8.self))")
            print("➡️ HEADERS: \(String(describing: endpoint.header))")
            //request.allHTTPHeaderFields?.forEach { print("⎯> \($0.key) : \($0.value)") }
#endif
            
            let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
            
            guard let response = response as? HTTPURLResponse else {
                return .failure(.noResponse)
            }
            
#if DEBUG
            print("➡️ status code: \(response.statusCode)")
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
               let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                print("✅ JSON String: \(String(decoding: jsonData, as: UTF8.self))")
                
                do{
                    let output = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                    print("🌴 from data object: \(String(describing: output?["message"]))")
                }
                catch {
                    print (error)
                }
            } else {
                print("json data malformed")
            }
#endif
            
            
            switch response.statusCode {
            case 200...299:
                do {
                    //Special case of PDF
                    if let invoiceUrl = request.url?.absoluteString {
                        if invoiceUrl.contains("/order/invoice") {
                            return .success(data as! T)
                        }
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(responseModel, from: data)
                    return .success(decodedResponse)
                }
                catch let DecodingError.dataCorrupted(context){
                    print(context)
                    return .failure(.decode)
                } catch let DecodingError.keyNotFound(key, context) {
                    print("Key '\(key)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                    return .failure(.decode)
                } catch let DecodingError.valueNotFound(value, context) {
                    print("Value '\(value)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                    return .failure(.decode)
                } catch let DecodingError.typeMismatch(type, context)  {
                    print("Type '\(type)' mismatch:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                    return .failure(.decode)
                } catch {
                    print("error: ", error)
                    //throw error
                    return .failure(.decode)
                }
            case 400:
                return .failure(.badRequest)
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.forbidden)
            case 404:
                return .failure(.dataNotFound)
            case 409:
                return .failure(.conflict)
            case 412:
                return .failure(.incorrectOTP)
            case 422:
                return .failure(.unprocessableEntity)
            case 423:
                return .failure(.locked)
            case 500...502:
                return .failure(.unexpectedStatusCode)
            default:
                return .failure(.unexpectedStatusCode)
            }
        } catch (let error) {
            print(error.localizedDescription)
            return .failure(.unknown)
        }
        
    }
    
    //MARK: - Upload
    
//    func upload<T: Decodable>(file: Data, endpoint: Endpoint, responseModel: T.Type) async -> Result<T, RequestError> {
//
//        guard var urlComponents = URLComponents(url: endpoint.baseUrl.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
//            return .failure(.invalidURL)
//        }
//
//        //        urlComponents.queryItems = endpoint.query?.map({ (key: String, value: Any) in
//        //            return URLQueryItem(name: key, value: value as? String)
//        //        })
//
//        guard let url = urlComponents.url else {
//            return .failure(.invalidURL)
//        }
//
//        // generate boundary string using a unique per-app string
//        let boundary = UUID().uuidString
//
//        // Set the URLRequest to POST and to the specified URL
//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = endpoint.method.rawValue
//
//        // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
//        // And the boundary is also set here
//        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        urlRequest.setValue("IIzwJQj39U2rqLSYWognMNsboxynogRx", forHTTPHeaderField: "API_KEY")
//
//        var requestData = Data()
//
//        // Add the image data to the raw http request data
//        requestData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
//        requestData.append("Content-Disposition: form-data; name=\"\("image")\"; filename=\"\("image")\"\r\n".data(using: .utf8)!)
//        requestData.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
//        requestData.append(file)
//
//        requestData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
//
//        // Send a POST request to the URL, with the data we created earlier
//        //let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
//        do {
//            let (data, response) = try await URLSession.shared.upload(for: urlRequest, from: requestData)
//
//            guard let response = response as? HTTPURLResponse else {
//                return .failure(.noResponse)
//            }
//
//#if DEBUG
//            print("➡️ status code: \(response.statusCode)")
//
//            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
//               let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
//                print("✅ JSON String: \(String(decoding: jsonData, as: UTF8.self))")
//
//                do{
//                    let output = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
//                    print("🌴 from data object: \(String(describing: output?["message"]))")
//                }
//                catch {
//                    print (error)
//                }
//            } else {
//                print("json data malformed")
//            }
//#endif
//
//            switch response.statusCode {
//            case 200...299:
//                do {
//
//                    let decodedResponse = try JSONDecoder().decode(responseModel, from: data)
//                    return .success(decodedResponse)
//                }
//                catch let DecodingError.dataCorrupted(context){
//                    print(context)
//                    return .failure(.decode)
//                } catch let DecodingError.keyNotFound(key, context) {
//                    print("Key '\(key)' not found:", context.debugDescription)
//                    print("codingPath:", context.codingPath)
//                    return .failure(.decode)
//                } catch let DecodingError.valueNotFound(value, context) {
//                    print("Value '\(value)' not found:", context.debugDescription)
//                    print("codingPath:", context.codingPath)
//                    return .failure(.decode)
//                } catch let DecodingError.typeMismatch(type, context)  {
//                    print("Type '\(type)' mismatch:", context.debugDescription)
//                    print("codingPath:", context.codingPath)
//                    return .failure(.decode)
//                } catch {
//                    print("error: ", error)
//                    //throw error
//                    return .failure(.decode)
//                }
//            case 401:
//                return .failure(.unauthorized)
//            case 403:
//                return .failure(.forbidden)
//            case 404:
//                return .failure(.dataNotFound)
//            case 500...502:
//                return .failure(.unexpectedStatusCode)
//            default:
//                return .failure(.unexpectedStatusCode)
//            }
//
//        } catch {
//            print(error)
//            return .failure(.unknown)
//        }
//    }
    
    
    func upload(file: Data) {
        
        let url = URL(string: "https://dev.katch.pro/api/v1/imageUpload?API_KEY=IIzwJQj39U2rqLSYWognMNsboxynogRx")
        
        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString
        
        let session = URLSession.shared
        
        // Set the URLRequest to POST and to the specified URL
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        
        // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
        // And the boundary is also set here
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("IIzwJQj39U2rqLSYWognMNsboxynogRx", forHTTPHeaderField: "API_KEY")
        
        var data = Data()
        
        // Add the image data to the raw http request data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\("image")\"; filename=\"\("image")\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        data.append(file)
        
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Send a POST request to the URL, with the data we created earlier
        session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
            if error == nil {
                let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
                if let json = jsonData as? [String: Any] {
                    print(json)
                }
            }
        }).resume()
    }
    
}
