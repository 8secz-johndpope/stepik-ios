//  Player.swift
//
//  Created by patrick piemonte on 11/26/14.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014-present patrick piemonte (http://patrickpiemonte.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import AVFoundation
import CoreGraphics
import Foundation
import UIKit

// MARK: - types

public enum PlaybackState: Int, CustomStringConvertible {
    case stopped = 0
    case playing
    case paused
    case failed

    public var description: String {
        get {
            switch self {
            case .stopped:
                return "Stopped"
            case .playing:
                return "Playing"
            case .failed:
                return "Failed"
            case .paused:
                return "Paused"
            }
        }
    }
}

public enum BufferingState: Int, CustomStringConvertible {
    case unknown = 0
    case ready
    case delayed

    public var description: String {
        get {
            switch self {
            case .unknown:
                return "Unknown"
            case .ready:
                return "Ready"
            case .delayed:
                return "Delayed"
            }
        }
    }
}

// MARK: - PlayerDelegate

@objc public protocol PlayerDelegate: NSObjectProtocol {
    @objc optional func playerReady(_ player: Player)
    @objc optional func playerPlaybackStateDidChange(_ player: Player)
    @objc optional func playerBufferingStateDidChange(_ player: Player)
    @objc optional func playerCurrentTimeDidChange(_ player: Player)

    @objc optional func playerPlaybackWillStartFromBeginning(_ player: Player)
    @objc optional func playerPlaybackDidEnd(_ player: Player)

    @objc optional func playerWillComeThroughLoop(_ player: Player)
}

// MARK: - Player

public class Player: UIViewController {
    public weak var delegate: PlayerDelegate?

    // configuration

    public func setUrl(_ url: URL) {
        // ensure everything is reset beforehand
        if self.playbackState == .playing {
            self.pause()
        }

        self.setupPlayerItem(nil)
        let asset = AVURLAsset(url: url, options: .none)
        self.setupAsset(asset)
    }

    public var muted: Bool {
        get {
            self.avplayer.isMuted
        }
        set {
            self.avplayer.isMuted = newValue
        }
    }

    public var fillMode: String {
        get {
            self.playerView.fillMode
        }
        set {
            self.playerView.fillMode = newValue
        }
    }

    // state

    public var playbackLoops: Bool {
        get {
            (self.avplayer.actionAtItemEnd == .none) as Bool
        }
        set {
            if newValue == true {
                self.avplayer.actionAtItemEnd = .none
            } else {
                self.avplayer.actionAtItemEnd = .pause
            }
        }
    }

    public var playbackFreezesAtEnd: Bool = false

    public var playbackState: PlaybackState = .stopped {
        didSet {
            if playbackState != oldValue || !playbackEdgeTriggered {
                self.delegate?.playerPlaybackStateDidChange?(self)
            }
        }
    }

    public var bufferingState: BufferingState = .unknown {
        didSet {
            if bufferingState != oldValue || !playbackEdgeTriggered {
                self.delegate?.playerBufferingStateDidChange?(self)
            }
        }
    }

    public var bufferSize: Double = 10

    public var playbackEdgeTriggered: Bool = true

    public var maximumDuration: TimeInterval {
        get {
            if let playerItem = self.playerItem {
                return CMTimeGetSeconds(playerItem.duration)
            } else {
                return CMTimeGetSeconds(CMTime.indefinite)
            }
        }
    }

    public var currentTime: TimeInterval {
        get {
            if let playerItem = self.playerItem {
                return CMTimeGetSeconds(playerItem.currentTime())
            } else {
                return CMTimeGetSeconds(CMTime.indefinite)
            }
        }
    }

    public var naturalSize: CGSize {
        get {
            if let playerItem = self.playerItem {
                let track = playerItem.asset.tracks(withMediaType: AVMediaType.video)[0]
                return track.naturalSize
            } else {
                return CGSize.zero
            }
        }
    }

    public var layerBackgroundColor: UIColor? {
        get {
            guard let backgroundColor = self.playerView.playerLayer.backgroundColor else { return nil }
            return UIColor(cgColor: backgroundColor)
        }
        set {
            self.playerView.playerLayer.backgroundColor = newValue?.cgColor
        }
    }

    private var periodicTimeObserver: AnyObject?

    private func getTimeFromBufferSize() {}

    //block's parameters are current current time + current buffered value 
    open func setPeriodicTimeObserver(_ block: @escaping (TimeInterval, TimeInterval?) -> Void) {
        let interval = CMTimeMakeWithSeconds(1, preferredTimescale: 10)
        periodicTimeObserver = self.avplayer.addPeriodicTimeObserver(
            forInterval: interval,
            queue: nil,
            using: { [weak self] time in
                let nTime = CMTimeGetSeconds(time)
                if let item = self?.playerItem {
                    if item.loadedTimeRanges.count > 0 {
                        let aTimeRange = item.loadedTimeRanges[0].timeRangeValue
                        let startTime = CMTimeGetSeconds(aTimeRange.start)
                        let loadedDuration = CMTimeGetSeconds(aTimeRange.duration)
                        block(nTime, startTime + loadedDuration)
                    } else {
                        print("ALERT loadedTimeTanges count < 0")
                        block(nTime, nil)
                    }
                }
            }
        ) as AnyObject?
    }

    // MARK: - private instance vars

    internal var asset: AVAsset!
    internal var avplayer: AVPlayer
    internal var playerItem: AVPlayerItem?
    internal var playerView: PlayerView!
    internal var timeObserver: Any!

    // MARK: - object lifecycle

    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        self.avplayer = AVPlayer()
        self.avplayer.actionAtItemEnd = .pause
        self.playbackFreezesAtEnd = false

        super.init(coder: aDecoder)
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.avplayer = AVPlayer()
        self.avplayer.actionAtItemEnd = .pause
        self.playbackFreezesAtEnd = false

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    deinit {
        if let obs = periodicTimeObserver {
            self.avplayer.removeTimeObserver(obs)
        }

        if self.timeObserver != nil {
            self.avplayer.removeTimeObserver(timeObserver!)
        }
        self.delegate = nil

        NotificationCenter.default.removeObserver(self)

        if self.playerView != nil {
            self.playerView.layer.removeObserver(
                self,
                forKeyPath: PlayerReadyForDisplayKey,
                context: &PlayerLayerObserverContext
            )
            self.playerView.player = nil
        }

        if self.avplayer.observationInfo != nil {
            self.avplayer.removeObserver(self, forKeyPath: PlayerRateKey, context: &PlayerObserverContext)
        }

        self.avplayer.pause()
        self.setupPlayerItem(nil)

        print("player is deinitialized")
    }

    // MARK: - view lifecycle

    override public func loadView() {
        self.playerView = PlayerView(frame: CGRect.zero)
        self.playerView.fillMode = AVLayerVideoGravity.resizeAspect.rawValue
        self.playerView.playerLayer.isHidden = true
        self.view = self.playerView
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("failed to set up background playing: \(error)")
        }

        self.playerView.layer.addObserver(
            self,
            forKeyPath: PlayerReadyForDisplayKey,
            options: ([.new, .old]),
            context: &PlayerLayerObserverContext
        )
        self.timeObserver = self.avplayer.addPeriodicTimeObserver(
            forInterval: CMTimeMake(value: 1, timescale: 100),
            queue: .main,
            using: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.delegate?.playerCurrentTimeDidChange?(strongSelf)
            }
        )

        self.avplayer.addObserver(
            self,
            forKeyPath: PlayerRateKey,
            options: ([.new, .old]),
            context: &PlayerObserverContext
        )

        self.addApplicationObservers()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.playbackState == .playing {
            self.pause()
        }
    }

    // MARK: - functions

    public func playFromBeginning() {
        self.delegate?.playerPlaybackWillStartFromBeginning?(self)
        self.avplayer.seek(to: CMTime.zero)
        self.playFromCurrentTime()
    }

    public func playFromCurrentTime() {
        if self.playbackState == .playing {
            return
        }
        self.playbackState = .playing
        self.avplayer.play()
        self.avplayer.rate = rate
    }

    public func pause() {
        if self.playbackState != .playing {
            return
        }

        self.avplayer.pause()
        self.playbackState = .paused
    }

    public func stop() {
        if self.playbackState == .stopped {
            return
        }

        self.avplayer.pause()
        self.playbackState = .stopped
        self.delegate?.playerPlaybackDidEnd?(self)
    }

    var rate: Float = 1 {
        didSet {
            print("\n\nrate: \(self.avplayer.rate)\n\n, setting to \(rate)")
            if self.avplayer.rate != 0 {
                self.avplayer.rate = rate
            }
        }
    }

    public func seekToTime(_ time: CMTime) {
        if let playerItem = self.playerItem {
            playerItem.seek(to: time, completionHandler: nil)
        }
    }

    // MARK: - private

    private func setupAsset(_ asset: AVAsset) {
        if self.playbackState == .playing {
            self.pause()
        }

        self.bufferingState = .unknown

        self.asset = asset
        if let _ = self.asset {
            self.setupPlayerItem(nil)
        }

        let keys: [String] = [PlayerTracksKey, PlayerPlayableKey, PlayerDurationKey]

        self.asset.loadValuesAsynchronously(forKeys: keys, completionHandler: { () -> Void in
            DispatchQueue.main.sync(execute: { () -> Void in
                for key in keys {
                    var error: NSError?
                    let status = self.asset.statusOfValue(forKey: key, error: &error)
                    if status == .failed {
                        self.playbackState = .failed
                        return
                    }
                }

                if self.asset.isPlayable == false {
                    self.playbackState = .failed
                    return
                }

                let playerItem = AVPlayerItem(asset: self.asset)
                self.setupPlayerItem(playerItem)
            })
        })
    }

    private func setupPlayerItem(_ playerItem: AVPlayerItem?) {
        if let currentPlayerItem = self.playerItem {
            currentPlayerItem.removeObserver(
                self,
                forKeyPath: PlayerEmptyBufferKey,
                context: &PlayerItemObserverContext
            )
            currentPlayerItem.removeObserver(
                self,
                forKeyPath: PlayerKeepUpKey,
                context: &PlayerItemObserverContext
            )
            currentPlayerItem.removeObserver(
                self,
                forKeyPath: PlayerStatusKey,
                context: &PlayerItemObserverContext
            )
            currentPlayerItem.removeObserver(
                self,
                forKeyPath: PlayerLoadedTimeRangesKey,
                context: &PlayerItemObserverContext
            )

            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: currentPlayerItem
            )
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemFailedToPlayToEndTime,
                object: currentPlayerItem
            )
        }

        self.playerItem = playerItem

        if let updatedPlayerItem = self.playerItem {
            updatedPlayerItem.addObserver(
                self,
                forKeyPath: PlayerEmptyBufferKey,
                options: ([.new, .old]),
                context: &PlayerItemObserverContext
            )
            updatedPlayerItem.addObserver(
                self,
                forKeyPath: PlayerKeepUpKey,
                options: ([.new, .old]),
                context: &PlayerItemObserverContext
            )
            updatedPlayerItem.addObserver(
                self,
                forKeyPath: PlayerStatusKey,
                options: ([.new, .old]),
                context: &PlayerItemObserverContext
            )
            updatedPlayerItem.addObserver(
                self,
                forKeyPath: PlayerLoadedTimeRangesKey,
                options: ([.new, .old]),
                context: &PlayerItemObserverContext
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemDidPlayToEndTime(_:)),
                name: .AVPlayerItemDidPlayToEndTime,
                object: updatedPlayerItem
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemFailedToPlayToEndTime(_:)),
                name: .AVPlayerItemFailedToPlayToEndTime,
                object: updatedPlayerItem
            )
        }

        let playbackLoops = self.playbackLoops

        self.avplayer.replaceCurrentItem(with: self.playerItem)

        // update new playerItem settings
        if playbackLoops == true {
            self.avplayer.actionAtItemEnd = .none
        } else {
            self.avplayer.actionAtItemEnd = .pause
        }
    }
}

// MARK: - NSNotifications

extension Player {
    // AVPlayerItem

    @objc internal func playerItemDidPlayToEndTime(_ aNotification: NSNotification) {
        if self.playbackLoops == true {
            self.delegate?.playerWillComeThroughLoop?(self)
            self.avplayer.seek(to: CMTime.zero)
        } else {
            if self.playbackFreezesAtEnd == true {
                self.stop()
            } else {
                self.avplayer.seek(to: CMTime.zero, completionHandler: { _ in
                    self.stop()
                })
            }
        }
    }

    @objc internal func playerItemFailedToPlayToEndTime(_ aNotification: NSNotification) {
        self.playbackState = .failed
    }

    // UIApplication

    internal func addApplicationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: UIApplication.shared
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: UIApplication.shared
        )
    }

    internal func removeApplicationObservers() {
    }

    @objc internal func handleApplicationDidBecomeActive(_ aNotification: Notification) {
        // Attach AVPlayer to AVPlayerLayer again
        playerView.player = self.avplayer
    }

    @objc internal func handleApplicationDidEnterBackground(_ aNotification: Notification) {
        // Detach AVPlayer from AVPlayerLayer (from Apple's manual)
        playerView.player = nil
        StepikAnalytics.shared.send(.videoPlayerDidEnterBackground)
    }
}

// MARK: - KVO

// KVO contexts

private var PlayerObserverContext = 0
private var PlayerItemObserverContext = 0
private var PlayerLayerObserverContext = 0

// KVO player keys

private let PlayerTracksKey = "tracks"
private let PlayerPlayableKey = "playable"
private let PlayerDurationKey = "duration"
private let PlayerRateKey = "rate"

// KVO player item keys

private let PlayerStatusKey = "status"
private let PlayerEmptyBufferKey = "playbackBufferEmpty"
private let PlayerKeepUpKey = "playbackLikelyToKeepUp"
private let PlayerLoadedTimeRangesKey = "loadedTimeRanges"

// KVO player layer keys

private let PlayerReadyForDisplayKey = "readyForDisplay"

extension Player {
    override public func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        // PlayerRateKey, PlayerObserverContext
        if context == &PlayerItemObserverContext {
            // PlayerStatusKey
            if keyPath == PlayerKeepUpKey {
                // PlayerKeepUpKey
                if let item = self.playerItem {
                    self.bufferingState = .ready

                    if item.isPlaybackLikelyToKeepUp && self.playbackState == .playing {
                        self.playFromCurrentTime()
                    }
                }

                let status = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).intValue as AVPlayer.Status.RawValue

                switch status {
                case AVPlayer.Status.readyToPlay.rawValue:
                    self.playerView.playerLayer.player = self.avplayer
                    self.playerView.playerLayer.isHidden = false
                case AVPlayer.Status.failed.rawValue:
                    self.playbackState = PlaybackState.failed
                default:
                    break
                }
            } else if keyPath == PlayerEmptyBufferKey {
                // PlayerEmptyBufferKey
                if let item = self.playerItem {
                    if item.isPlaybackBufferEmpty {
                        self.bufferingState = .delayed
                    }
                }

                let status = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).intValue as AVPlayer.Status.RawValue

                switch status {
                case AVPlayer.Status.readyToPlay.rawValue:
                    self.playerView.playerLayer.player = self.avplayer
                    self.playerView.playerLayer.isHidden = false
                case AVPlayer.Status.failed.rawValue:
                    self.playbackState = PlaybackState.failed
                default:
                    break
                }
            } else if keyPath == PlayerLoadedTimeRangesKey {
                // PlayerLoadedTimeRangesKey
                if let item = self.playerItem {
                    self.bufferingState = .ready

                    let timeRanges = item.loadedTimeRanges
                    let timeRange: CMTimeRange = timeRanges[0].timeRangeValue
                    let bufferedTime = CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration))
                    let currentTime = CMTimeGetSeconds(item.currentTime())

                    if (bufferedTime - currentTime) >= self.bufferSize && self.playbackState == .playing {
                        self.playFromCurrentTime()
                    }
                }
            }
        } else if context == &PlayerLayerObserverContext {
            self.executeClosureOnMainQueueIfNecessary(withClosure: {
                if self.playerView.playerLayer.isReadyForDisplay {
                    self.delegate?.playerReady?(self)
                }
            })
        }
    }
}

// MARK: - queues

extension Player {
    internal func executeClosureOnMainQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async(execute: closure)
        }
    }
}

// MARK: - PlayerView

internal class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var fillMode: String {
        get {
            (self.layer as! AVPlayerLayer).videoGravity.rawValue
        }
        set {
            (self.layer as! AVPlayerLayer).videoGravity = AVLayerVideoGravity(rawValue: newValue)
        }
    }

    override class var layerClass: Swift.AnyClass {
        get {
            AVPlayerLayer.self
        }
    }

    // MARK: - object lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.playerLayer.backgroundColor = UIColor.black.cgColor
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.playerLayer.backgroundColor = UIColor.black.cgColor
    }
}
