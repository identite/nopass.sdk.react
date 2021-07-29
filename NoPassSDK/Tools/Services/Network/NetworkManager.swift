import Foundation


open class NetworkManager: NSObject {
    
    // SINGLETON
    static let shared = NetworkManager()
    
    // OTHER VARIABLES
    typealias CompletionBlock = (_ results: Any?, _ error: NSError?) -> Void
    
    
    //MARK: - SENT REQUEST
    
    func sendRequest(urlString: String!,
                     params: [String: Any]?,
                     completion: CompletionBlock?,
                     method: String,
                     urlEncoding: ParameterEncoding,
                     requestTag: Int, timeoutInterval: Double = 120) {
        
        
        if !Connectivity.isConnectedToInternet {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to find an internet connection. Please check your connection and try again."])
            completion?(nil, error)
            return
        }
        
        var request = URLRequest(url: URL(string: urlString)!)
        
        if let dataDict = params {
            let json = JSON(dataDict)
            let str = json.description
            let data = str.data(using: String.Encoding.utf8)!
            request.httpBody = data
        }
        
        request.allHTTPHeaderFields = self.headers(requestTag: requestTag)
        request.httpMethod = HTTPMethod(rawValue: method)!.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval
        
            
        let dataRequest: DataRequest = request111(request)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON
            { [weak self] response in
                if (response.response != nil) {
                    self?.logResponse(response.response!, response.data)
                }
                
                self?.handleResponse(response: response,
                                     completion: completion,
                                     requestTag: requestTag,
                                     urlString: urlString,
                                     method: method,
                                     urlEncoding: urlEncoding,
                                     params: params)
                
        }
        
        if dataRequest.request != nil {
            self.logRequest(dataRequest.request!, params: params)
        }
    }
    
    
    
    
    
    //MARK: - REQUESTS CANCELATION
    
    func cancelRequest(requestPath: String) {
        let cancelationUrl: URL? = URL(string: requestPath)
        if cancelationUrl != nil {
            let lastPath = cancelationUrl?.lastPathComponent
            SessionManager.default.session.getAllTasks { (tasks) in
                tasks.forEach({ task in
                    if task.currentRequest?.url?.lastPathComponent == lastPath
                    {
                        task.cancel()
                    }
                })
            }
        }
    }
    
    func cancelAllRequests() {
        SessionManager.default.session.getAllTasks { (tasks) in
            
            tasks.forEach({ $0.cancel() })
        }
    }
    
    // MARK: Headers
    
    func headers(requestTag: Int) -> [String: String] {
        var headers = [String: String]()
        headers["Cache-Control"] = "no-cache"
        headers["Content-Type"] = "application/json;charset=UTF-8"
        return headers
    }
    
    // MARK: - HANDLE REQUEST
    
    func handleResponse(response: DataResponse<Any>,
                        completion: CompletionBlock?,
                        requestTag: Int,
                        urlString: String!,
                        method: String,
                        urlEncoding: ParameterEncoding,
                        params: [String: Any]?)
    {
        
        if response.response == nil {
            if self.isNoInternetConnection(response: response) {
                completion!(nil, self.error("No internet connection", code: -1009))
                return
            }
            
            completion!(nil, self.error("Uknown server error: 500", code: 500))
            return
        }
        let statusCode = response.response?.statusCode
        
        if statusCode == nil {
            completion!(nil, self.error("Uknown server error", code: 500))
            return
        }
  
        
        if statusCode == 200 {
            if let json = try? JSON(data: response.data!) {
                completion!(json, nil)
            } else {
                completion!(response.data, nil)
            }
        } else if statusCode == 201 {
            let headers = response.response?.allHeaderFields
            completion!(headers, nil)
        } else if let json = try? JSON(data: response.data ?? Data()) {
            let errorMessage = json["errors"].arrayValue.first?["message"].stringValue ?? "Ups.. Server is temporary unavailable. Please try later"
            let errorCode = json["errors"].arrayValue.first?["code"].intValue ?? 500
            completion!(json, self.error(errorMessage, code: errorCode))
            return
        }else if statusCode == 404 {
            if let json = try? JSON(data: response.data ?? Data()) {
                let errorMessage = json["errors"].arrayValue.first?["message"].stringValue ?? "Ups.. Server is temporary unavailable. Please try later"
                let errorCode = json["errors"].arrayValue.first?["code"].intValue ?? 500
                completion!(json, self.error(errorMessage, code: errorCode))
                return
            }
            completion!(nil, self.error("Ups.. Server is temporary unavailable. Please try later", code: 404))
        } else if statusCode == 302 {
            completion!(nil, self.error("Record is already exists", code: 302))
        } else if statusCode == 456 {
            completion!(nil, self.error("User does not have payment method", code: 456))
        } else if statusCode == 400 {
            let errorMsg = "Server error: 400 bad request"
            completion!(nil, self.error(errorMsg, code: 400))
        } else if statusCode == 417 {
            if let json = try? JSON(data: response.data ?? Data()) {
                let errorMessage = json["errors"].arrayValue.first?["message"].stringValue ?? "Ups.. Server is temporary unavailable. Please try later"
                let errorCode = json["errors"].arrayValue.first?["code"].intValue ?? 417
                completion!(json, self.error(errorMessage, code: errorCode))
                return
            }
            completion!(nil, self.error("Server error: 417", code: 417))
        } else if statusCode == 422 {
            if let json = try? JSON(data: response.data ?? Data()) {
                let errorMessage = json["errors"].arrayValue.first?["message"].stringValue ?? "Ups.. Server is temporary unavailable. Please try later"
                let errorCode = json["errors"].arrayValue.first?["code"].intValue ?? 500
                completion!(json, self.error(errorMessage, code: errorCode))
                return
            }
            completion!(nil, self.error("Server error: 422 Client Error", code: 422))
        } else if statusCode == 454 {
            completion!(nil, self.error("The entered password is incorrect", code: 454))
        } else if statusCode == 401 {
            self.cancelAllRequests()
        } else if statusCode == 502 {
            completion!(nil, self.error("Ups.. Server is temporary unavailable. Please try later", code: 502))
        } else if statusCode == 500 || statusCode == 400 {
            if let json = try? JSON(data: response.data ?? Data()) {
                let errorMessage = json["errors"].arrayValue.first?["message"].stringValue ?? "Uknown server error: 500"
                completion!(json, self.error(errorMessage, code: 500))
            }
            completion!(nil, self.error("Uknown server error: 500", code: 500))
        }
    }
    
    func isNoInternetConnection(response: DataResponse<Any>) -> Bool {
        var isConnected = false
        switch response.result {
        case .failure(let error):
            let code = (error as NSError).code
            if code == -1009 {
                isConnected = true
            } else if code == -1005 {
                isConnected = true
            }
        default:
            break
        }
        return isConnected
    }
    
    // MARK: Logging
    
    func logRequest(_ request: URLRequest, params: [String: Any]?) {
        let method = request.httpMethod
        let urlString = request.url?.absoluteString
        
        logMessage("\(method!) \(urlString!)")
        
        let headers = request.allHTTPHeaderFields
        self.logHeaders(headers!)
        
        if let postParams = params {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: postParams, options: JSONSerialization.WritingOptions.prettyPrinted)
                let datastring = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
                logMessage("Post body : \n \(datastring!)")
                // here "jsonData" is the dictionary encoded in JSON data
            } catch let error as NSError {
                logMessage(error.localizedDescription)
            }
        }
    }
    
    func logResponse(_ response: URLResponse, _ data: Data?) {
        if let url = response.url?.absoluteString {
            logMessage("\n Response: \(url)")
        }
        if let httpResponse = response as? HTTPURLResponse {
            let localisedStatus = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode).capitalized
            logMessage("Status: \(httpResponse.statusCode) - \(localisedStatus)")
        }
        
        if let headers = (response as? HTTPURLResponse)?.allHeaderFields as? [String: AnyObject] {
            self.logHeaders(headers)
        }
        
        if (data?.count)! > 0 {
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                let pretty = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                if let string = NSString(data: pretty, encoding: String.Encoding.utf8.rawValue) {
                    logMessage(" Response: \(response.url?.absoluteString)\n JSON: \(string)")
                }
            }
                
            catch {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
                    print("Data: \(string)")
                }
            }
        }
    }
    
    func logHeaders(_ headers: [String: Any]) {
        logMessage("Headers: [")
        var stringHeaders = ""
        for (key, value) in headers {
            stringHeaders += "  \(key) : \(value) \n"
            
        }
        logMessage("Headers: \n[\(stringHeaders)]")
    }
    
    func doLogout() {
        self.cancelAllRequests()
    }
    
    func error(_ errorMsg: String, code: Int) -> NSError {
        let userInfo: [String: Any] =
            [
                NSLocalizedDescriptionKey: NSLocalizedString("Unauthorized", value: errorMsg, comment: ""),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("Unauthorized", value: errorMsg, comment: "")
        ]
        let err = NSError(domain: "Domain", code: code, userInfo: userInfo)
        return err
    }
    
    private func isDisconnected(_ handler: ((_ isConnected: Bool) -> Void)?) {
        let barrier = DispatchQueue(label: "Barrier", attributes: .concurrent)
        barrier.sync {
            handler?(NetworkReachabilityManager()!.isReachable)
        }
    }
}




