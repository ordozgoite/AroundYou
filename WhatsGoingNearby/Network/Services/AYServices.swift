//
//  AYServices.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

protocol AYServiceable {
    
    // User
    func postNewUser(name: String, token: String) async -> Result<MongoUser, RequestError>
    func getUserInfo(token: String) async -> Result<MongoUser, RequestError>
    func getUserProfile(userUid: String, token: String) async -> Result<UserProfile, RequestError>
    func editProfile(name: String, biography: String, token: String) async -> Result<EditProfileResponse, RequestError>
    
    // Publication
    func postNewPublication(text: String, latitude: Double, longitude: Double, token: String) async -> Result<Post, RequestError>
    func deletePublication(publicationId: String, token: String) async -> Result<DeletePublicationResponse, RequestError>
    func getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String) async -> Result<[FormattedPost], RequestError>
    func getAllPublicationsByUser(token: String) async -> Result<[FormattedPost], RequestError>
    func likePublication(publicationId: String, token: String) async -> Result<LikePublicationResponse, RequestError>
    func unlikePublication(publicationId: String, token: String) async -> Result<UnlikePublicationResponse, RequestError>
    
    // Comment
    func postNewComment(publicationId: String, text: String, token: String) async -> Result<PostNewCommentResponse, RequestError>
    func deleteComment(commentId: String, token: String) async -> Result<DeleteCommentResponse, RequestError>
    func getAllCommentsByPublication(publicationId: String, token: String) async -> Result<[FormattedComment], RequestError>
    
    // Report
    func postNewReport(report: ReportDTO, token: String) async -> Result<Report, RequestError>
    
    // BugReport
    func postNewBugReport(bugDescription: String, token: String) async -> Result<BugReport, RequestError>
    
    // Block
    func blockUser(blockedUserUid: String, token: String) async -> Result<Block, RequestError>
    func getBlockedUsers(token: String) async -> Result<[UserProfile], RequestError>
    func unblockUser(blockedUserUid: String, token: String) async -> Result<UnblockUserResponse, RequestError>
}

struct AYServices: HTTPClient, AYServiceable {
    
    static let shared = AYServices()
    private init() {}
    
    //MARK: - User
    
    func postNewUser(name: String, token: String) async -> Result<MongoUser, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewUser(name: name, token: token), responseModel: MongoUser.self)
    }
    
    func getUserInfo(token: String) async -> Result<MongoUser, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getUserInfo(token: token), responseModel: MongoUser.self)
    }
    
    func getUserProfile(userUid: String, token: String) async -> Result<UserProfile, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getUserProfile(userUid: userUid, token: token), responseModel: UserProfile.self)
    }
    
    func editProfile(name: String, biography: String, token: String) async -> Result<EditProfileResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.editProfile(name: name, biography: biography, token: token), responseModel: EditProfileResponse.self)
    }
    
    //MARK: - Publication
    
    func postNewPublication(text: String, latitude: Double, longitude: Double, token: String) async -> Result<Post, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewPublication(text: text, latitude: latitude, longitude: longitude, token: token), responseModel: Post.self)
    }
    
    func deletePublication(publicationId: String, token: String) async -> Result<DeletePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.deletePublication(publicationId: publicationId, token: token), responseModel: DeletePublicationResponse.self)
    }
    
    func getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String) async -> Result<[FormattedPost], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getActivePublicationsNearBy(latitude: latitude, longitude: longitude, token: token), responseModel: [FormattedPost].self)
    }
    
    func getAllPublicationsByUser(token: String) async -> Result<[FormattedPost], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getAllPublicationsByUser(token: token), responseModel: [FormattedPost].self)
    }
    
    func likePublication(publicationId: String, token: String) async -> Result<LikePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.likePublication(publicationId: publicationId, token: token), responseModel: LikePublicationResponse.self)
    }
    
    func unlikePublication(publicationId: String, token: String) async -> Result<UnlikePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.unlikePublication(publicationId: publicationId, token: token), responseModel: UnlikePublicationResponse.self)
    }
    
    //MARK: - Comment
    
    func postNewComment(publicationId: String, text: String, token: String) async -> Result<PostNewCommentResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewComment(publicationId: publicationId, text: text, token: token), responseModel: PostNewCommentResponse.self)
    }
    
    func deleteComment(commentId: String, token: String) async -> Result<DeleteCommentResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.deleteComment(commentId: commentId, token: token), responseModel: DeleteCommentResponse.self)
    }
    
    func getAllCommentsByPublication(publicationId: String, token: String) async -> Result<[FormattedComment], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getAllCommentsByPublication(publicationId: publicationId, token: token), responseModel: [FormattedComment].self)
    }
    
    //MARK: - Report
    
    func postNewReport(report: ReportDTO, token: String) async -> Result<Report, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewReport(report: report, token: token), responseModel: Report.self)
    }
    
    //MARK: - Bug Report
    
    func postNewBugReport(bugDescription: String, token: String) async -> Result<BugReport, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewBugReport(bugDescription: bugDescription, token: token), responseModel: BugReport.self)
    }
    
    //MARK: - Block
    
    func blockUser(blockedUserUid: String, token: String) async -> Result<Block, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.blockUser(blockedUserUid: blockedUserUid, token: token), responseModel: Block.self)
    }
    
    func getBlockedUsers(token: String) async -> Result<[UserProfile], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getBlockedUsers(token: token), responseModel: [UserProfile].self)
    }
    
    func unblockUser(blockedUserUid: String, token: String) async -> Result<UnblockUserResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.unblockUser(blockedUserUid: blockedUserUid, token: token), responseModel: UnblockUserResponse.self)
    }
}
