//
//  NotificationReactionHandler.swift
//  Stepic
//
//  Created by Alexander Karpov on 13.05.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

/*
 Chooses the appropriate reaction to the notification click
 */
class NotificationReactionHandler {
    
    func handleNotificationWithUserInfo(userInfo: [NSObject: AnyObject]) -> (UIViewController -> Void)? {
        
        if !StepicAPI.shared.isAuthorized {
            return nil
        }
        
        let notificationObject : [String: AnyObject] = userInfo["object"] as! [String: AnyObject]
        if let notification = Notification(dictionary: notificationObject) {
            switch notification.type {
            case NotificationType.Learn:
                return handleLearnNotification(notification)
            case NotificationType.Comments:
                return handleCommentsNotification(notification)
            }
        }
        return nil
    }
    
    private func handleLearnNotification(notification: Notification) -> (UIViewController -> Void)? {
        let extractor = NotificationDataExtractor(notification: notification)
        if let courseId = extractor.getCourseId() {
            
            var course : Course? = nil
            do { 
                course = try Course.getCourses([courseId])[0]
            } 
            catch {
                print("No course with appropriate id \(courseId) found")
                return nil
            }
            let sectionsCOpt = ControllerHelper.instantiateViewController(identifier: "SectionsViewController") as? SectionsViewController
            print(sectionsCOpt)
            if let sectionsController = sectionsCOpt,
                course = course {
                sectionsController.course = course
                
                let res : (UIViewController -> Void) = {
                    controller in
                    print("in res handler -> \(controller)")
                    controller.navigationController?.pushViewController(sectionsController, animated: false)
                }
                
                return res
            }
        } 
        return nil
    }
    
    private func handleCommentsNotification(notification: Notification) -> (UIViewController -> Void)? {
        let extractor = NotificationDataExtractor(notification: notification)
        if let commentsURL = extractor.getCommentsURL() {     
            
            let res : (UIViewController -> Void) = {
                controller in
                
                delay(1, closure: {
                    let alert = NotificationAlertConstructor.sharedConstructor.getOpenCommentNotificationViaSafariAlertController({
                        UIThread.performUI {
                            WebControllerManager.sharedManager.presentWebControllerWithURL(commentsURL, inController: controller, withKey: "external link", allowsSafari: true, backButtonStyle:    BackButtonStyle.Close, animated: true)
                        }
                    })
                    controller.presentViewController(alert, animated: true, completion: nil)
                })  
            }
            return res

        } 
        return nil
    }
    
}