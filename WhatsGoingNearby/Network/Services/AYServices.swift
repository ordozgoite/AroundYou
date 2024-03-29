//
//  AYServices.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

protocol AYServiceable {
    
    // User
    func postNewUser(username: String, name: String?, userRegistrationToken: String, token: String) async -> Result<MongoUser, RequestError>
    func getUserInfo(userRegistrationToken: String?, preferredLanguage: String?, token: String) async -> Result<MongoUser, RequestError>
    func getUserProfile(userUid: String, token: String) async -> Result<UserProfile, RequestError>
    func editProfile(profile: UserProfileDTO, token: String) async -> Result<EditProfileResponse, RequestError>
    func deleteProfilePic(token: String) async -> Result<EditProfileResponse, RequestError>
    func deleteUser(token: String) async -> Result<DeleteUserResponse, RequestError>
    
    // Publication
    func postNewPublication(text: String, tag: String, postDuration: Int, latitude: Double, longitude: Double, isLocationVisible: Bool, token: String) async -> Result<Post, RequestError>
    func deletePublication(publicationId: String, token: String) async -> Result<DeletePublicationResponse, RequestError>
    func getAllPublicationsNearBy(latitude: Double, longitude: Double, token: String) async -> Result<[FormattedPost], RequestError>
    func getAllPublicationsByUser(token: String) async -> Result<[FormattedPost], RequestError>
    func getPublication(publicationId: String, latitude: Double, longitude: Double, token: String) async -> Result<FormattedPost, RequestError>
    func likePublication(publicationId: String, latitude: Double, longitude: Double, token: String) async -> Result<LikePublicationResponse, RequestError>
    func unlikePublication(publicationId: String, latitude: Double, longitude: Double, token: String) async -> Result<UnlikePublicationResponse, RequestError>
    func getPublicationLikes(publicationId: String, token: String) async -> Result<[UserProfile], RequestError>
    func checkNearByPublications(userUid: String, latitude: Double, longitude: Double) async -> Result<CheckNearByPublicationsResponse, RequestError>
    
    // Comment
    func postNewComment(comment: CommentDTO, latitude: Double, longitude: Double, token: String) async -> Result<PostNewCommentResponse, RequestError>
    func deleteComment(commentId: String, token: String) async -> Result<DeleteCommentResponse, RequestError>
    func getAllCommentsByPublication(publicationId: String, token: String) async -> Result<[FormattedComment], RequestError>
    func likeComment(commentId: String, latitude: Double, longitude: Double, token: String) async -> Result<LikePublicationResponse, RequestError> // criar response model
    func unlikeComment(commentId: String, latitude: Double, longitude: Double, token: String) async -> Result<UnlikePublicationResponse, RequestError> // criar response model
    func getCommentLikes(commentId: String, token: String) async -> Result<[UserProfile], RequestError>
    
    // Chat
    func postNewChat(otherUserUid: String, token: String) async -> Result<Chat, RequestError>
    func getChatsByUser(token: String) async -> Result<[FormattedChat], RequestError>
    func muteChat(chatId: String, token: String) async -> Result<MuteChatResponse, RequestError>
    func unmuteChat(chatId: String, token: String) async -> Result<MuteChatResponse, RequestError>
    
    // Message
    func postNewMessage(chatId: String, text: String, token: String) async -> Result<Message, RequestError>
    func getMessages(chatId: String, token: String) async -> Result<[FormattedMessage], RequestError>
    func deleteMessage(messageId: String, token: String) async -> Result<DeleteMessageResponse, RequestError>
    
    // Report
    func postNewReport(report: ReportDTO, token: String) async -> Result<Report, RequestError>
    
    // BugReport
    func postNewBugReport(bugDescription: String, token: String) async -> Result<BugReport, RequestError>
    
    // Block
    func blockUser(blockedUserUid: String, token: String) async -> Result<Block, RequestError>
    func getBlockedUsers(token: String) async -> Result<[UserProfile], RequestError>
    func unblockUser(blockedUserUid: String, token: String) async -> Result<UnblockUserResponse, RequestError>
    
    // Notification
    func getUserNotifications(token: String) async -> Result<[FormattedNotification], RequestError>
    func deleteNotification(notificationId: String, token: String) async -> Result<DeleteNotificationResponse, RequestError>
    
    // Subscription
    func subscribeUserToPublication(publicationId: String, token: String) async -> Result<Subscription, RequestError>
    func unsubscribeUser(publicationId: String, token: String) async -> Result<Subscription, RequestError>
    
    // Ban
    func getUserBanExpireDate(token: String) async -> Result<GetUserBanExpireDateResponse, RequestError>
}

struct AYServices: HTTPClient, AYServiceable {
    
    static let shared = AYServices()
    private init() {}
    
    //MARK: - User
    
    func postNewUser(username: String, name: String?, userRegistrationToken: String, token: String) async -> Result<MongoUser, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewUser(username: username, name: name, userRegistrationToken: userRegistrationToken, token: token), responseModel: MongoUser.self)
    }
    
    func getUserInfo(userRegistrationToken: String? = nil, preferredLanguage: String? = nil, token: String) async -> Result<MongoUser, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getUserInfo(userRegistrationToken: userRegistrationToken, preferredLanguage: preferredLanguage, token: token), responseModel: MongoUser.self)
    }
    
    func getUserProfile(userUid: String, token: String) async -> Result<UserProfile, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getUserProfile(userUid: userUid, token: token), responseModel: UserProfile.self)
    }
    
    func editProfile(profile: UserProfileDTO, token: String) async -> Result<EditProfileResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.editProfile(profile: profile, token: token), responseModel: EditProfileResponse.self)
    }
    
    func deleteProfilePic(token: String) async -> Result<EditProfileResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.deleteProfilePic(token: token), responseModel: EditProfileResponse.self)
    }
    
    func deleteUser(token: String) async -> Result<DeleteUserResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.deleteUser(token: token), responseModel: DeleteUserResponse.self)
    }
    
    //MARK: - Publication
    
    func postNewPublication(text: String, tag: String, postDuration: Int, latitude: Double, longitude: Double, isLocationVisible: Bool, token: String) async -> Result<Post, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewPublication(text: text, tag: tag, postDuration: postDuration, latitude: latitude, longitude: longitude, isLocationVisible: isLocationVisible, token: token), responseModel: Post.self)
    }
    
    func deletePublication(publicationId: String, token: String) async -> Result<DeletePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.deletePublication(publicationId: publicationId, token: token), responseModel: DeletePublicationResponse.self)
    }
    
    func getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String) async -> Result<[FormattedPost], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getActivePublicationsNearBy(latitude: latitude, longitude: longitude, token: token), responseModel: [FormattedPost].self)
    }
    
    func getAllPublicationsNearBy(latitude: Double, longitude: Double, token: String) async -> Result<[FormattedPost], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getAllPublicationsNearBy(latitude: latitude, longitude: longitude, token: token), responseModel: [FormattedPost].self)
    }
    
    func getAllPublicationsByUser(token: String) async -> Result<[FormattedPost], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getAllPublicationsByUser(token: token), responseModel: [FormattedPost].self)
    }
    
    func getPublication(publicationId: String, latitude: Double, longitude: Double, token: String) async -> Result<FormattedPost, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getPublication(publicationId: publicationId, latitude: latitude,longitude: longitude, token: token), responseModel: FormattedPost.self)
    }
    
    func likePublication(publicationId: String, latitude: Double, longitude: Double, token: String) async -> Result<LikePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.likePublication(publicationId: publicationId, latitude: latitude, longitude: longitude, token: token), responseModel: LikePublicationResponse.self)
    }
    
    func unlikePublication(publicationId: String, latitude: Double, longitude: Double, token: String) async -> Result<UnlikePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.unlikePublication(publicationId: publicationId, latitude: latitude, longitude: longitude, token: token), responseModel: UnlikePublicationResponse.self)
    }
    
    func getPublicationLikes(publicationId: String, token: String) async -> Result<[UserProfile], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getPublicationLikes(publicationId: publicationId, token: token), responseModel: [UserProfile].self)
    }
    
    func checkNearByPublications(userUid: String, latitude: Double, longitude: Double) async -> Result<CheckNearByPublicationsResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.checkNearByPublications(userUid: userUid, latitude: latitude, longitude: longitude), responseModel: CheckNearByPublicationsResponse.self)
    }
    
    //MARK: - Comment
    
    func postNewComment(comment: CommentDTO, latitude: Double, longitude: Double, token: String) async -> Result<PostNewCommentResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewComment(comment: comment, latitude: latitude, longitude: longitude, token: token), responseModel: PostNewCommentResponse.self)
    }
    
    func deleteComment(commentId: String, token: String) async -> Result<DeleteCommentResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.deleteComment(commentId: commentId, token: token), responseModel: DeleteCommentResponse.self)
    }
    
    func getAllCommentsByPublication(publicationId: String, token: String) async -> Result<[FormattedComment], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getAllCommentsByPublication(publicationId: publicationId, token: token), responseModel: [FormattedComment].self)
    }
    
    func likeComment(commentId: String, latitude: Double, longitude: Double, token: String) async -> Result<LikePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.likeComment(commentId: commentId, latitude: latitude, longitude: longitude, token: token), responseModel: LikePublicationResponse.self )
    }
    
    func unlikeComment(commentId: String, latitude: Double, longitude: Double, token: String) async -> Result<UnlikePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.unlikeComment(commentId: commentId, latitude: latitude, longitude: longitude, token: token), responseModel: UnlikePublicationResponse.self)
    }
    
    func getCommentLikes(commentId: String, token: String) async -> Result<[UserProfile], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getCommentLikes(commentId: commentId, token: token), responseModel: [UserProfile].self)
    }
    
    //MARK: - Chat
    
    func postNewChat(otherUserUid: String, token: String) async -> Result<Chat, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewChat(otherUserUid: otherUserUid, token: token), responseModel: Chat.self)
    }
    
    func getChatsByUser(token: String) async -> Result<[FormattedChat], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getChatsByUser(token: token), responseModel: [FormattedChat].self)
    }
    
    func muteChat(chatId: String, token: String) async -> Result<MuteChatResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.muteChat(chatId: chatId, token: token), responseModel: MuteChatResponse.self)
    }
    
    func unmuteChat(chatId: String, token: String) async -> Result<MuteChatResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.unmuteChat(chatId: chatId, token: token), responseModel: MuteChatResponse.self)
    }
    
    //MARK: - Message
    
    func postNewMessage(chatId: String, text: String, token: String) async -> Result<Message, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewMessage(chatId: chatId, text: text, token: token), responseModel: Message.self)
    }
    
    func getMessages(chatId: String, token: String) async -> Result<[FormattedMessage], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getMessages(chatId: chatId, token: token), responseModel: [FormattedMessage].self)
    }
    
    func deleteMessage(messageId: String, token: String) async -> Result<DeleteMessageResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.deleteMessage(messageId: messageId, token: token), responseModel: DeleteMessageResponse.self)
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
    
    //MARK: - Notification
    
    func getUserNotifications(token: String) async -> Result<[FormattedNotification], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getUserNotifications(token: token), responseModel: [FormattedNotification].self)
    }
    
    func deleteNotification(notificationId: String, token: String) async -> Result<DeleteNotificationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.deleteNotification(notificationId: notificationId, token: token), responseModel: DeleteNotificationResponse.self)
    }
    
    //MARK: - Subscription
    
    func subscribeUserToPublication(publicationId: String, token: String) async -> Result<Subscription, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.subscribeUserToPublication(publicationId: publicationId, token: token), responseModel: Subscription.self)
    }
    
    func unsubscribeUser(publicationId: String, token: String) async -> Result<Subscription, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.unsubscribeUser(publicationId: publicationId, token: token), responseModel: Subscription.self)
    }
    
    //MARK: - Ban
    
    func getUserBanExpireDate(token: String) async -> Result<GetUserBanExpireDateResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getUserBanExpireDate(token: token), responseModel: GetUserBanExpireDateResponse.self)
    }
}
