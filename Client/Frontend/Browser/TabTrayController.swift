/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Storage
import ReadingList
import Shared

struct TabTrayControllerUX {
    static let CornerRadius = CGFloat(BraveUX.TabTrayCellCornerRadius)
    static let BackgroundColor = UIConstants.AppBackgroundColor
    static let CellBackgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1)
    static let TextBoxHeight = CGFloat(32.0)
    static let FaviconSize = CGFloat(BraveUX.TabTrayCellFaviconSize)
    static let Margin = CGFloat(15)
    static let ToolbarBarTintColor = UIConstants.AppBackgroundColor
    static let ToolbarButtonOffset = CGFloat(10.0)
    static let CloseButtonSize = CGFloat(BraveUX.TabTrayCellCloseButtonSize)
    static let CloseButtonMargin = CGFloat(2.0)
    static let CloseButtonEdgeInset = CGFloat(6)

    static let NumberOfColumnsThin = 1
    static let NumberOfColumnsWide = 3
    static let CompactNumberOfColumnsThin = 2

    // Moved from UIConstants temporarily until animation code is merged
    static var StatusBarHeight: CGFloat {
        if UIScreen.mainScreen().traitCollection.verticalSizeClass == .Compact {
            return 0
        }
        return 20
    }
}

struct LightTabCellUX {
    static let TabTitleTextColor = UIColor.blackColor()
}

struct DarkTabCellUX {
    static let TabTitleTextColor = UIColor.whiteColor()
}

protocol TabCellDelegate: class {
    func tabCellDidClose(cell: TabCell)
}

class TabCell: UICollectionViewCell {
    enum Style {
        case Light
        case Dark
    }

    static let Identifier = "TabCellIdentifier"

    var style: Style = .Light {
        didSet {
            applyStyle(style)
        }
    }

    let backgroundHolder = UIView()
    let background = UIImageViewAligned()
    let titleText: UILabel
    let innerStroke: InnerStrokedView
    let favicon: UIImageView = UIImageView()
    let closeButton: UIButton

    var title: UIVisualEffectView!
    var animator: SwipeAnimator!

    weak var delegate: TabCellDelegate?

    // Changes depending on whether we're full-screen or not.
    var margin = CGFloat(0)

    override init(frame: CGRect) {
        self.backgroundHolder.backgroundColor = UIColor.whiteColor()
        self.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        self.backgroundHolder.clipsToBounds = true
        self.backgroundHolder.backgroundColor = TabTrayControllerUX.CellBackgroundColor

        self.background.contentMode = UIViewContentMode.ScaleAspectFill
        self.background.clipsToBounds = true
        self.background.userInteractionEnabled = false
        self.background.alignLeft = true
        self.background.alignTop = true

        self.favicon.layer.cornerRadius = 2.0
        self.favicon.layer.masksToBounds = true

        self.titleText = UILabel()
        self.titleText.textAlignment = NSTextAlignment.Left
        self.titleText.userInteractionEnabled = false
        self.titleText.numberOfLines = 1
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold

        self.closeButton = UIButton()
        self.closeButton.setImage(UIImage(named: "stop"), forState: UIControlState.Normal)
        self.closeButton.tintColor = UIColor.lightGrayColor()
       // self.closeButton.imageEdgeInsets = UIEdgeInsetsMake(TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset)

        self.innerStroke = InnerStrokedView(frame: self.backgroundHolder.frame)
        self.innerStroke.layer.backgroundColor = UIColor.clearColor().CGColor

        super.init(frame: frame)

        //self.opaque = true

        self.animator = SwipeAnimator(animatingView: self.backgroundHolder, container: self)
        self.closeButton.addTarget(self, action: #selector(TabCell.SELclose), forControlEvents: UIControlEvents.TouchUpInside)

        contentView.addSubview(backgroundHolder)
        backgroundHolder.addSubview(self.background)
        backgroundHolder.addSubview(innerStroke)

        // Default style is light
        applyStyle(style)

        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: Strings.Close, target: self.animator, selector: #selector(SELclose))
        ]
    }

    private func applyStyle(style: Style) {
        self.title?.removeFromSuperview()

        let title: UIVisualEffectView
        switch style {
        case .Light:
            title = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
            self.titleText.textColor = LightTabCellUX.TabTitleTextColor
        case .Dark:
            title = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
            self.titleText.textColor = DarkTabCellUX.TabTitleTextColor
        }

        titleText.backgroundColor = UIColor.clearColor()

        title.layer.shadowColor = UIColor.blackColor().CGColor
        title.layer.shadowOpacity = 0.2
        title.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        title.layer.shadowRadius = 0

        title.addSubview(self.closeButton)
        title.addSubview(self.titleText)
        backgroundHolder.addSubview(self.favicon)

        backgroundHolder.addSubview(title)
        self.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        closeButton.tintColor = BraveUX.ProgressBarColor

        backgroundHolder.snp_makeConstraints { make in
            make.edges.equalTo(backgroundHolder.superview!)
        }

        background.snp_makeConstraints { make in
            make.bottom.left.right.equalTo(background.superview!)
            make.top.equalTo(background.superview!).offset(TabTrayControllerUX.TextBoxHeight)
        }

        favicon.snp_makeConstraints { make in
            make.bottom.left.equalTo(favicon.superview!)
            make.width.height.equalTo(TabTrayControllerUX.FaviconSize)
        }

        title.snp_makeConstraints { make in
            make.left.top.equalTo(title.superview!)
            make.width.equalTo(title.superview!.snp_width)
            make.height.equalTo(TabTrayControllerUX.TextBoxHeight)
        }

        innerStroke.snp_makeConstraints { make in
            make.edges.equalTo(background)
        }

        titleText.snp_makeConstraints { make in
            make.left.equalTo(closeButton.snp_right)
            make.top.right.bottom.equalTo(titleText.superview!)
        }

        closeButton.snp_makeConstraints { make in
            make.size.equalTo(title.snp_height)
            make.centerY.equalTo(title)
            make.left.equalTo(closeButton.superview!)
        }

        let top = (TabTrayControllerUX.TextBoxHeight - titleText.bounds.height) / 2.0
        titleText.frame.origin = CGPoint(x: titleText.frame.origin.x, y: max(0, top))
    }


    override func prepareForReuse() {
        // Reset any close animations.
        backgroundHolder.transform = CGAffineTransformIdentity
        backgroundHolder.alpha = 1
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
    }

    override func accessibilityScroll(direction: UIAccessibilityScrollDirection) -> Bool {
        var right: Bool
        switch direction {
        case .Left:
            right = false
        case .Right:
            right = true
        default:
            return false
        }
        animator.close(right: right)
        return true
    }

    @objc
    func SELclose() {
        self.animator.SELcloseWithoutGesture()
    }
}

struct PrivateModeStrings {
    static let toggleAccessibilityLabel = Strings.Private_Mode
    static let toggleAccessibilityHint = Strings.Turns_private_mode_on_or_off
    static let toggleAccessibilityValueOn = Strings.On
    static let toggleAccessibilityValueOff = Strings.Off
}

protocol TabTrayDelegate: class {
    func tabTrayDidDismiss(tabTray: TabTrayController)
    func tabTrayDidAddBookmark(tab: Browser)
    func tabTrayDidAddToReadingList(tab: Browser) -> ReadingListClientRecord?
    func tabTrayRequestsPresentationOf(viewController viewController: UIViewController)
}

class TabTrayController: UIViewController {
    let tabManager: TabManager
    let profile: Profile
    weak var delegate: TabTrayDelegate?

    var collectionView: UICollectionView!
    var navBar: UIView!
    var addTabButton: UIButton!
    var collectionViewTransitionSnapshot: UIView?

    private(set) internal var privateMode: Bool = false {
        didSet {
#if !BRAVE_NO_PRIVATE_MODE
    togglePrivateMode.selected = privateMode
    togglePrivateMode.accessibilityValue = privateMode ? PrivateModeStrings.toggleAccessibilityValueOn : PrivateModeStrings.toggleAccessibilityValueOff
    tabDataSource.updateData()
    collectionView?.reloadData()
#endif
        }
    }

    private var tabsToDisplay: [Browser] {
        return tabManager.tabs.displayedTabsForCurrentPrivateMode
    }

#if !BRAVE_NO_PRIVATE_MODE
    lazy var togglePrivateMode: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Private, forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Selected)
        button.setTitleColor(UIColor(white: 255/255.0, alpha: 1.0), forState: .Normal)
        button.titleLabel!.font = UIFont.systemFontOfSize(button.titleLabel!.font.pointSize + 2)
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 4 /* left */, 0, 4 /* right */)
        button.addTarget(self, action: #selector(TabTrayController.SELdidTogglePrivateMode), forControlEvents: .TouchUpInside)
        button.accessibilityLabel = PrivateModeStrings.toggleAccessibilityLabel
        button.accessibilityHint = PrivateModeStrings.toggleAccessibilityHint
        button.accessibilityValue = self.privateMode ? PrivateModeStrings.toggleAccessibilityValueOn : PrivateModeStrings.toggleAccessibilityValueOff
        button.accessibilityIdentifier = "TabTrayController.togglePrivateMode"

        if PrivateBrowsing.singleton.isOn {
            button.backgroundColor = UIColor.whiteColor()
            button.layer.cornerRadius = 4.0
            button.selected = true
        }
        return button
    }()

    private lazy var emptyPrivateTabsView: EmptyPrivateTabsView = {
        let emptyView = EmptyPrivateTabsView()
        emptyView.learnMoreButton.addTarget(self, action: #selector(TabTrayController.SELdidTapLearnMore), forControlEvents: UIControlEvents.TouchUpInside)
        return emptyView
    }()
#endif
    private lazy var tabDataSource: TabManagerDataSource = {
        return TabManagerDataSource(cellDelegate: self)
    }()

    private lazy var tabLayoutDelegate: TabLayoutDelegate = {
        let delegate = TabLayoutDelegate(profile: self.profile, traitCollection: self.traitCollection)
        delegate.tabSelectionDelegate = self
        return delegate
    }()

#if BRAVE
    override func dismissViewControllerAnimated(flag: Bool, completion: (() -> Void)?) {

        super.dismissViewControllerAnimated(flag, completion:completion)

        UIView.animateWithDuration(0.2) {
            let braveTopVC = getApp().rootViewController.topViewController as? BraveTopViewController
            braveTopVC?.view.backgroundColor = BraveUX.TopLevelBackgroundColor
             getApp().browserViewController.view.alpha = 1.0
             getApp().browserViewController.toolbar?.leavingTabTrayMode()
        }

        getApp().browserViewController.updateTabCountUsingTabManager(getApp().tabManager)
    }
#endif

    init(tabManager: TabManager, profile: Profile) {
        self.tabManager = tabManager
        self.profile = profile
        super.init(nibName: nil, bundle: nil)

        tabManager.addDelegate(self)
    }

    convenience init(tabManager: TabManager, profile: Profile, tabTrayDelegate: TabTrayDelegate) {
        self.init(tabManager: tabManager, profile: profile)
        self.delegate = tabTrayDelegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
        self.tabManager.removeDelegate(self)
    }

    func SELDynamicFontChanged(notification: NSNotification) {
        guard notification.name == NotificationDynamicFontChanged else { return }

        self.collectionView.reloadData()
    }

    @objc func onTappedBackground(gesture: UITapGestureRecognizer) {
        dismissViewControllerAnimated(true, completion: nil)
    }

// MARK: View Controller Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityLabel = Strings.Tabs_Tray

        navBar = UIView()
        navBar.backgroundColor = TabTrayControllerUX.BackgroundColor

        addTabButton = UIButton()
        addTabButton.setImage(UIImage(named: "add")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        addTabButton.addTarget(self, action: #selector(TabTrayController.SELdidClickAddTab), forControlEvents: .TouchUpInside)
        addTabButton.accessibilityLabel = Strings.Add_Tab
        addTabButton.accessibilityIdentifier = "TabTrayController.addTabButton"
        addTabButton.tintColor = UIColor.whiteColor() // makes it stand out more

        let flowLayout = TabTrayCollectionViewLayout()
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: flowLayout)

        collectionView.dataSource = tabDataSource
        collectionView.delegate = tabLayoutDelegate

        collectionView.registerClass(TabCell.self, forCellWithReuseIdentifier: TabCell.Identifier)
        collectionView.backgroundColor = UIColor.clearColor()

#if BRAVE
        collectionView.backgroundView = UIView(frame: view.frame)
        collectionView.backgroundView?.snp_makeConstraints() {
            make in
            make.edges.equalTo(collectionView)
        }
        collectionView.backgroundView?.userInteractionEnabled = true
        collectionView.backgroundView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TabTrayController.onTappedBackground(_:))))
#endif

        view.addSubview(collectionView)
        view.addSubview(navBar)
        view.addSubview(addTabButton)


        makeConstraints()
#if !BRAVE_NO_PRIVATE_MODE
        if profile.prefs.boolForKey(kPrefKeyPrivateBrowsingAlwaysOn) ?? false {
            togglePrivateMode.hidden = true
        }

        view.addSubview(togglePrivateMode)
        togglePrivateMode.snp_makeConstraints { make in
            make.right.equalTo(addTabButton.snp_left).offset(-10)
            //make.height.equalTo(UIConstants.ToolbarHeight)
            make.centerY.equalTo(self.navBar)
        }

        view.insertSubview(emptyPrivateTabsView, aboveSubview: collectionView)
        emptyPrivateTabsView.alpha = privateTabsAreEmpty() ? 1 : 0
        emptyPrivateTabsView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        if let tab = tabManager.selectedTab  where tab.isPrivate {
            privateMode = true
        } else if PrivateBrowsing.singleton.isOn {
            privateMode = true
        }

        // register for previewing delegate to enable peek and pop if force touch feature available
//            if traitCollection.forceTouchCapability == .Available {
//                registerForPreviewingWithDelegate(self, sourceView: view)
//            }

#endif

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TabTrayController.SELappWillResignActiveNotification), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TabTrayController.SELappDidBecomeActiveNotification), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TabTrayController.SELDynamicFontChanged(_:)), name: NotificationDynamicFontChanged, object: nil)
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Update the trait collection we reference in our layout delegate
        tabLayoutDelegate.traitCollection = traitCollection
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({ _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    private func makeConstraints() {
        navBar.snp_makeConstraints { make in
            make.top.equalTo(snp_topLayoutGuideBottom)
            make.height.equalTo(UIConstants.ToolbarHeight)
            make.left.right.equalTo(self.view)
        }

        addTabButton.snp_makeConstraints { make in
            make.trailing.bottom.equalTo(self.navBar)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }

        collectionView.snp_makeConstraints { make in
            make.top.equalTo(navBar.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }
    }

// MARK: Selectors

    func SELdidClickAddTab() {
        openNewTab()
    }
  #if !BRAVE_NO_PRIVATE_MODE
    func SELdidTapLearnMore() {
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        if let langID = NSLocale.preferredLanguages().first {
            let learnMoreRequest = NSURLRequest(URL: "https://support.mozilla.org/1/mobile/\(appVersion)/iOS/\(langID)/private-browsing-ios".asURL!)
            openNewTab(learnMoreRequest)
        }
    }
    
    func SELdidTogglePrivateMode() {
        telemetry(action: "Private mode button tapped", props: nil)

        let scaleDownTransform = CGAffineTransformMakeScale(0.9, 0.9)

        let fromView: UIView
        if privateTabsAreEmpty() {
            fromView = emptyPrivateTabsView
        } else {
            let snapshot = collectionView.snapshotViewAfterScreenUpdates(false)
            snapshot!.frame = collectionView.frame
            view.insertSubview(snapshot!, aboveSubview: collectionView)
            fromView = snapshot!
        }

        privateMode = !privateMode
#if BRAVE
        if privateMode {
            PrivateBrowsing.singleton.enter()
            togglePrivateMode.backgroundColor = UIColor.whiteColor()
            togglePrivateMode.layer.cornerRadius = 4.0
        } else {
            self.togglePrivateMode.backgroundColor = UIColor.clearColor()
            view.userInteractionEnabled = false
            view.alpha = 0.5
            let activityView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
            activityView.center = view.center
            activityView.startAnimating()
            self.view.addSubview(activityView)

            PrivateBrowsing.singleton.exit().uponQueue(dispatch_get_main_queue()) {
                self.view.userInteractionEnabled = true
                self.view.alpha = 1.0
                activityView.stopAnimating()
            }
        }
        tabDataSource.updateData()
#else
        // If we are exiting private mode and we have the close private tabs option selected, make sure
        // we clear out all of the private tabs
        if !privateMode && profile.prefs.boolForKey("settings.closePrivateTabs") ?? false {
            tabManager.removeAllPrivateTabsAndNotify(false)
        }

        togglePrivateMode.setSelected(privateMode, animated: true)
#endif

        collectionView.layoutSubviews()

        let toView: UIView
        if privateTabsAreEmpty() {
            toView = emptyPrivateTabsView
        } else {
            let newSnapshot = collectionView.snapshotViewAfterScreenUpdates(true)
            newSnapshot!.frame = collectionView.frame
            view.insertSubview(newSnapshot!, aboveSubview: fromView)
            collectionView.alpha = 0
            toView = newSnapshot!
        }
        toView.alpha = 0
        toView.transform = scaleDownTransform

        UIView.animateWithDuration(0.2, delay: 0, options: [], animations: { () -> Void in
            fromView.transform = scaleDownTransform
            fromView.alpha = 0
            toView.transform = CGAffineTransformIdentity
            toView.alpha = 1
        }) { finished in
            if fromView != self.emptyPrivateTabsView {
                fromView.removeFromSuperview()
            }
            if toView != self.emptyPrivateTabsView {
                toView.removeFromSuperview()
            }
            self.collectionView.alpha = 1
        }
    }

    private func privateTabsAreEmpty() -> Bool {
        return privateMode && tabManager.tabs.privateTabs.count == 0
    }
#endif

    func changePrivacyMode(isPrivate: Bool) {
#if !BRAVE_NO_PRIVATE_MODE
        if isPrivate != privateMode {
            guard let _ = collectionView else {
                privateMode = isPrivate
                return
            }
            SELdidTogglePrivateMode()
        }
#endif
    }

    private func openNewTab(request: NSURLRequest? = nil) {
#if !BRAVE_NO_PRIVATE_MODE
        if privateMode {
            emptyPrivateTabsView.hidden = true
        }
#endif
        // We're only doing one update here, but using a batch update lets us delay selecting the tab
        // until after its insert animation finishes.
        self.collectionView.performBatchUpdates({ _ in
            var tab: Browser?
#if !BRAVE_NO_PRIVATE_MODE
            tab = self.tabManager.addTab(request, isPrivate: self.privateMode)

#else
            tab = self.tabManager.addTab(request)
#endif
            if let tab = tab {
                self.tabManager.selectTab(tab)
            }
        }, completion: { finished in
            if finished {
                #if BRAVE
                    self.dismissViewControllerAnimated(true, completion: nil)
                #else
                    self.navigationController?.popViewControllerAnimated(true)
                #endif
            }
        })
    }
}

// MARK: - App Notifications
extension TabTrayController {
    func SELappWillResignActiveNotification() {
        if privateMode {
            collectionView.alpha = 0
        }
    }

    func SELappDidBecomeActiveNotification() {
        // Re-show any components that might have been hidden because they were being displayed
        // as part of a private mode tab
        UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.collectionView.alpha = 1
        },
        completion: nil)
    }
}

extension TabTrayController: TabSelectionDelegate {
    func didSelectTabAtIndex(index: Int) {
        let tab = tabsToDisplay[index]
        tabManager.selectTab(tab)
        #if BRAVE
            self.dismissViewControllerAnimated(true, completion: nil)
        #else
            self.navigationController?.popViewControllerAnimated(true)
        #endif
    }
}

extension TabTrayController: PresentingModalViewControllerDelegate {
    func dismissPresentedModalViewController(modalViewController: UIViewController, animated: Bool) {
        dismissViewControllerAnimated(animated, completion: { self.collectionView.reloadData() })
    }
}

extension TabTrayController: TabManagerDelegate {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?) {
    }

    func tabManager(tabManager: TabManager, didCreateWebView tab: Browser, url: NSURL?) {
    }

    func tabManager(tabManager: TabManager, didAddTab tab: Browser) {
        // Get the index of the added tab from it's set (private or normal)
        guard let index = tabsToDisplay.indexOf(tab) else { return }

        tabDataSource.updateData()

        self.collectionView?.performBatchUpdates({ _ in
            self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
        }, completion: { finished in
            if finished {
                tabManager.selectTab(tab)
                // don't pop the tab tray view controller if it is not in the foreground
                if self.presentedViewController == nil {
                    #if BRAVE
                        self.dismissViewControllerAnimated(true, completion: nil)
                    #else
                        self.navigationController?.popViewControllerAnimated(true)
                    #endif
                }
            }
        })
    }

    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser) {
        var removedIndex = -1
        for i in 0..<tabDataSource.tabList.count() {
            let tabRef = tabDataSource.tabList.at(i)
            if tabRef == nil || getApp().tabManager.tabs.displayedTabsForCurrentPrivateMode.indexOf(tabRef!) == nil {
                removedIndex = i
                break
            }
        }

        tabDataSource.updateData()
        if (removedIndex < 0) {
            return
        }

        self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: removedIndex, inSection: 0)])

        // Workaround: On iOS 8.* devices, cells don't get reloaded during the deletion but after the
        // animation has finished which causes cells that animate from above to suddenly 'appear'. This
        // is fixed on iOS 9 but for iOS 8 we force a reload on non-visible cells during the animation.
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_8_3) {
            let visibleCount = collectionView.indexPathsForVisibleItems().count
            var offscreenIndexPaths = [NSIndexPath]()
            for i in 0..<(tabsToDisplay.count - visibleCount) {
                offscreenIndexPaths.append(NSIndexPath(forItem: i, inSection: 0))
            }
            self.collectionView.reloadItemsAtIndexPaths(offscreenIndexPaths)
        }
#if !BRAVE_NO_PRIVATE_MODE
        if privateTabsAreEmpty() {
            emptyPrivateTabsView.alpha = 1
        }
#endif
    }

    func tabManagerDidAddTabs(tabManager: TabManager) {
    }

    func tabManagerDidRestoreTabs(tabManager: TabManager) {
    }
}

extension TabTrayController: UIScrollViewAccessibilityDelegate {
    func accessibilityScrollStatusForScrollView(scrollView: UIScrollView) -> String? {
        var visibleCells = collectionView.visibleCells() as! [TabCell]
        var bounds = collectionView.bounds
        bounds = CGRectOffset(bounds, collectionView.contentInset.left, collectionView.contentInset.top)
        bounds.size.width -= collectionView.contentInset.left + collectionView.contentInset.right
        bounds.size.height -= collectionView.contentInset.top + collectionView.contentInset.bottom
        // visible cells do sometimes return also not visible cells when attempting to go past the last cell with VoiceOver right-flick gesture; so make sure we have only visible cells (yeah...)
        visibleCells = visibleCells.filter { !CGRectIsEmpty(CGRectIntersection($0.frame, bounds)) }

        let cells = visibleCells.map { self.collectionView.indexPathForCell($0)! }
        let indexPaths = cells.sort { (a: NSIndexPath, b: NSIndexPath) -> Bool in
            return a.section < b.section || (a.section == b.section && a.row < b.row)
        }

        if indexPaths.count == 0 {
            return Strings.No_tabs
        }

        let firstTab = indexPaths.first!.row + 1
        let lastTab = indexPaths.last!.row + 1
        let tabCount = collectionView.numberOfItemsInSection(0)

        if (firstTab == lastTab) {
            let format = Strings.Tab_xofx_template
            return String(format: format, NSNumber(integer: firstTab), NSNumber(integer: tabCount))
        } else {
            let format = Strings.Tabs_xtoxofx_template
            return String(format: format, NSNumber(integer: firstTab), NSNumber(integer: lastTab), NSNumber(integer: tabCount))
        }
    }
}

private func removeTabUtil(tabManager: TabManager, tab: Browser) {
    let isAlwaysPrivate = getApp().profile?.prefs.boolForKey(kPrefKeyPrivateBrowsingAlwaysOn) ?? false
    let createIfNone =  isAlwaysPrivate ? true : !PrivateBrowsing.singleton.isOn
    tabManager.removeTab(tab, createTabIfNoneLeft: createIfNone)
}

extension TabTrayController: SwipeAnimatorDelegate {
    func swipeAnimator(animator: SwipeAnimator, viewWillExitContainerBounds: UIView) {
        let tabCell = animator.container as! TabCell
        if let indexPath = collectionView.indexPathForCell(tabCell) {
            let tab = tabsToDisplay[indexPath.item]
            removeTabUtil(tabManager, tab: tab)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, Strings.Closing_tab)
        }
    }
}

extension TabTrayController: TabCellDelegate {
    func tabCellDidClose(cell: TabCell) {
        let indexPath = collectionView.indexPathForCell(cell)!
        let tab = tabsToDisplay[indexPath.item]
        removeTabUtil(tabManager, tab: tab)
    }
}

extension TabTrayController: SettingsDelegate {
    func settingsOpenURLInNewTab(url: NSURL) {
        let request = NSURLRequest(URL: url)
        openNewTab(request)
    }
}

private class TabManagerDataSource: NSObject, UICollectionViewDataSource {
    unowned var cellDelegate: protocol<TabCellDelegate, SwipeAnimatorDelegate>

    private var tabList = WeakList<Browser>()

    init(cellDelegate: protocol<TabCellDelegate, SwipeAnimatorDelegate>) {
        self.cellDelegate = cellDelegate
        super.init()

        getApp().tabManager.tabs.displayedTabsForCurrentPrivateMode.forEach {
            tabList.insert($0)
        }
    }

    func updateData() {
        tabList = WeakList<Browser>()
        getApp().tabManager.tabs.displayedTabsForCurrentPrivateMode.forEach {
            tabList.insert($0)
        }
    }

    @objc func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let tabCell = collectionView.dequeueReusableCellWithReuseIdentifier(TabCell.Identifier, forIndexPath: indexPath) as! TabCell
        tabCell.animator.delegate = cellDelegate
        tabCell.delegate = cellDelegate

        guard let tab = tabList.at(indexPath.item) else {
            assert(false)
            return tabCell
        }
        tabCell.style = tab.isPrivate ? .Dark : .Light
        tabCell.titleText.text = tab.displayTitle

        if !tab.displayTitle.isEmpty {
            tabCell.accessibilityLabel = tab.displayTitle
        } else {
            tabCell.accessibilityLabel = AboutUtils.getAboutComponent(tab.url)
        }

        tabCell.isAccessibilityElement = true
        tabCell.accessibilityHint = Strings.Swipe_right_or_left_with_three_fingers_to_close_the_tab

        if let favIcon = tab.displayFavicon {
            tabCell.favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
            tabCell.favicon.backgroundColor = BraveUX.TabTrayCellBackgroundColor
        } else {
            tabCell.favicon.image = nil
        }
        
        tabCell.background.image = tab.screenshot.image
        tab.screenshot.listenerImages.removeAll() // TODO maybe UIImageWithNotify should only ever have one listener?
        tab.screenshot.listenerImages.append(UIImageWithNotify.WeakImageView(tabCell.background))
        
        return tabCell
    }

    @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabList.count()
    }
}

@objc protocol TabSelectionDelegate: class {
    func didSelectTabAtIndex(index :Int)
}

private class TabLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    weak var tabSelectionDelegate: TabSelectionDelegate?

    private var traitCollection: UITraitCollection
    private var profile: Profile
    private var numberOfColumns: Int {
        let compactLayout = profile.prefs.boolForKey("CompactTabLayout") ?? true

        // iPhone 4-6+ portrait
        if traitCollection.horizontalSizeClass == .Compact && traitCollection.verticalSizeClass == .Regular {
            return compactLayout ? TabTrayControllerUX.CompactNumberOfColumnsThin : TabTrayControllerUX.NumberOfColumnsThin
        } else {
            return TabTrayControllerUX.NumberOfColumnsWide
        }
    }

    init(profile: Profile, traitCollection: UITraitCollection) {
        self.profile = profile
        self.traitCollection = traitCollection
        super.init()
    }

    private func cellHeightForCurrentDevice() -> CGFloat {
        let compactLayout = profile.prefs.boolForKey("CompactTabLayout") ?? true
        let shortHeight = (compactLayout ? TabTrayControllerUX.TextBoxHeight * 6 : TabTrayControllerUX.TextBoxHeight * 5)

        if self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact {
            return shortHeight
        } else if self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact {
            return shortHeight
        } else {
            return TabTrayControllerUX.TextBoxHeight * 8
        }
    }

    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let cellWidth = floor((collectionView.bounds.width - TabTrayControllerUX.Margin * CGFloat(numberOfColumns + 1)) / CGFloat(numberOfColumns))
        return CGSizeMake(cellWidth, self.cellHeightForCurrentDevice())
    }

    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin)
    }

    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    @objc func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }
}

// There seems to be a bug with UIKit where when the UICollectionView changes its contentSize
// from > frame.size to <= frame.size: the contentSet animation doesn't properly happen and 'jumps' to the
// final state.
// This workaround forces the contentSize to always be larger than the frame size so the animation happens more
// smoothly. This also makes the tabs be able to 'bounce' when there are not enough to fill the screen, which I
// think is fine, but if needed we can disable user scrolling in this case.
private class TabTrayCollectionViewLayout: UICollectionViewFlowLayout {
    private override func collectionViewContentSize() -> CGSize {
        var calculatedSize = super.collectionViewContentSize()
        let collectionViewHeight = collectionView?.bounds.size.height ?? 0
        if calculatedSize.height < collectionViewHeight && collectionViewHeight > 0 {
            calculatedSize.height = collectionViewHeight + 1
        }
        return calculatedSize
    }
}

struct EmptyPrivateTabsViewUX {
    static let TitleColor = UIColor.whiteColor()
    static let TitleFont = UIFont.systemFontOfSize(22, weight: UIFontWeightMedium)
    static let DescriptionColor = UIColor.whiteColor()
    static let DescriptionFont = UIFont.systemFontOfSize(17)
    static let LearnMoreFont = UIFont.systemFontOfSize(15, weight: UIFontWeightMedium)
    static let TextMargin: CGFloat = 18
    static let LearnMoreMargin: CGFloat = 30
    static let MaxDescriptionWidth: CGFloat = 250
}

// View we display when there are no private tabs created
private class EmptyPrivateTabsView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = EmptyPrivateTabsViewUX.TitleColor
        label.font = EmptyPrivateTabsViewUX.TitleFont
        label.textAlignment = NSTextAlignment.Center
        return label
    }()

    private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = EmptyPrivateTabsViewUX.DescriptionColor
        label.font = EmptyPrivateTabsViewUX.DescriptionFont
        label.textAlignment = NSTextAlignment.Center
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = EmptyPrivateTabsViewUX.MaxDescriptionWidth
        return label
    }()

    private var learnMoreButton: UIButton = {
        let button = UIButton(type: .System)
        button.setTitle(Strings.Learn_More, forState: .Normal)
        button.setTitleColor(UIConstants.PrivateModeTextHighlightColor, forState: .Normal)
        button.titleLabel?.font = EmptyPrivateTabsViewUX.LearnMoreFont
        return button
    }()

#if !BRAVE
    private var iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "largePrivateMask"))
        return imageView
    }()
#endif
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)

        titleLabel.text = Strings.Private_Browsing
        descriptionLabel.text = Strings.Brave_wont_remember_any_of_your_history

        addSubview(titleLabel)
        addSubview(descriptionLabel)
#if !BRAVE
        addSubview(iconImageView)
        addSubview(learnMoreButton)
#endif
        titleLabel.snp_makeConstraints { make in
            make.center.equalTo(self)
        }

        descriptionLabel.snp_makeConstraints { make in
            make.top.equalTo(titleLabel.snp_bottom).offset(EmptyPrivateTabsViewUX.TextMargin)
            make.centerX.equalTo(self)
        }

#if !BRAVE
        iconImageView.snp_makeConstraints { make in
            make.bottom.equalTo(titleLabel.snp_top).offset(-EmptyPrivateTabsViewUX.TextMargin)
            make.centerX.equalTo(self)
        }

        learnMoreButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(descriptionLabel.snp_bottom).offset(EmptyPrivateTabsViewUX.LearnMoreMargin)
            make.centerX.equalTo(self)
        }
#endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//@available(iOS 9.0, *)
//extension TabTrayController: TabPeekDelegate {
//
//    func tabPeekDidAddBookmark(tab: Browser) {
//        delegate?.tabTrayDidAddBookmark(tab)
//    }
//
//    func tabPeekDidAddToReadingList(tab: Browser) -> ReadingListClientRecord? {
//        return delegate?.tabTrayDidAddToReadingList(tab)
//    }
//
//    func tabPeekDidCloseTab(tab: Browser) {
//        if let index = self.tabDataSource.tabs.indexOf(tab),
//            let cell = self.collectionView?.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) as? TabCell {
//            cell.SELclose()
//        }
//    }
//
//    func tabPeekRequestsPresentationOf(viewController viewController: UIViewController) {
//        delegate?.tabTrayRequestsPresentationOf(viewController: viewController)
//    }
//}

//@available(iOS 9.0, *)
//extension TabTrayController: UIViewControllerPreviewingDelegate {
//
//    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
//
//        guard let collectionView = collectionView else { return nil }
//        let convertedLocation = self.view.convertPoint(location, toView: collectionView)
//
//        guard let indexPath = collectionView.indexPathForItemAtPoint(convertedLocation),
//            let cell = collectionView.cellForItemAtIndexPath(indexPath) else { return nil }
//
//        let tab = tabDataSource.tabs[indexPath.row]
//        let tabVC = TabPeekViewController(tab: tab, delegate: self)
//        if let browserProfile = profile as? BrowserProfile {
//            tabVC.setState(withProfile: browserProfile, clientPickerDelegate: self)
//        }
//        previewingContext.sourceRect = self.view.convertRect(cell.frame, fromView: collectionView)
//
//        return tabVC
//    }
//
//    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
//        guard let tpvc = viewControllerToCommit as? TabPeekViewController else { return }
//        tabManager.selectTab(tpvc.tab)
//
//        #if BRAVE
//            self.dismissViewControllerAnimated(true, completion: nil)
//        #else
//            self.navigationController?.popViewControllerAnimated(true)
//        #endif
//
//        delegate?.tabTrayDidDismiss(self)
//
//    }
//}

//extension TabTrayController: ClientPickerViewControllerDelegate {
//
//    func clientPickerViewController(clientPickerViewController: ClientPickerViewController, didPickClients clients: [RemoteClient]) {
//        if let item = clientPickerViewController.shareItem {
//            self.profile.sendItems([item], toClients: clients)
//        }
//        clientPickerViewController.dismissViewControllerAnimated(true, completion: nil)
//    }
//
//    func clientPickerViewControllerDidCancel(clientPickerViewController: ClientPickerViewController) {
//        clientPickerViewController.dismissViewControllerAnimated(true, completion: nil)
//    }
//}
