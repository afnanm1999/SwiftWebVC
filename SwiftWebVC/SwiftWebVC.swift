//
//  SwiftWebVC.swift
//
//  Created by Myles Ringle on 24/06/2015.
//  Transcribed from code used in SVWebViewController.
//  Copyright (c) 2015 Myles Ringle & Sam Vermette. All rights reserved.
//

import WebKit

public protocol SwiftWebVCDelegate: class {
    func didStartLoading()
    func didFinishLoading(success: Bool)
}

public class SwiftWebVC: UIViewController {

    public weak var delegate: SwiftWebVCDelegate?
    var storedStatusColor: UIBarStyle = .default
    var buttonColor: UIColor?
    var titleColor: UIColor?
    var closing = false

    var request: URLRequest!
    var navBarTitle = UILabel()
    var sharingEnabled = true
    var hideToolBar = false

    lazy var backBarButtonItem: UIBarButtonItem = {
        var tempBackBarButtonItem = UIBarButtonItem(image: SwiftWebVC.bundledImage(named: "SwiftWebVCBack"),
                                                    style: .plain,
                                                    target: self,
                                                    action: #selector(SwiftWebVC.goBackTapped(_:)))
        tempBackBarButtonItem.width = 18.0
        tempBackBarButtonItem.tintColor = self.buttonColor
        return tempBackBarButtonItem
    }()

    lazy var forwardBarButtonItem: UIBarButtonItem = {
        var tempForwardBarButtonItem = UIBarButtonItem(image: SwiftWebVC.bundledImage(named: "SwiftWebVCNext"),
                                                       style: .plain,
                                                       target: self,
                                                       action: #selector(SwiftWebVC.goForwardTapped(_:)))
        tempForwardBarButtonItem.width = 18.0
        tempForwardBarButtonItem.tintColor = self.buttonColor
        return tempForwardBarButtonItem
    }()

    lazy var refreshBarButtonItem: UIBarButtonItem = {
        var tempRefreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                       target: self,
                                                       action: #selector(SwiftWebVC.reloadTapped(_:)))
        tempRefreshBarButtonItem.tintColor = self.buttonColor
        return tempRefreshBarButtonItem
    }()

    lazy var stopBarButtonItem: UIBarButtonItem = {
        var tempStopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
                                                    target: self,
                                                    action: #selector(SwiftWebVC.stopTapped(_:)))
        tempStopBarButtonItem.tintColor = self.buttonColor
        return tempStopBarButtonItem
    }()

    lazy var actionBarButtonItem: UIBarButtonItem = {
        var tempActionBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                                      target: self,
                                                      action: #selector(SwiftWebVC.actionButtonTapped(_:)))
        tempActionBarButtonItem.tintColor = self.buttonColor
        return tempActionBarButtonItem
    }()

    lazy var webView: WKWebView = {
        var tempWebView = WKWebView(frame: UIScreen.main.bounds)
        tempWebView.navigationDelegate = self
        return tempWebView
    }()

    ////////////////////////////////////////////////
    public convenience init(urlString: String, sharingEnabled: Bool = true, hideToolBar: Bool = false) {
        var urlString = urlString
        if !urlString.hasPrefix("https://") && !urlString.hasPrefix("http://") {
            urlString = "https://"+urlString
        }

        self.init(pageURL: URL(string: urlString)!, sharingEnabled: sharingEnabled, hideToolBar: hideToolBar)
    }

    public convenience init(pageURL: URL, sharingEnabled: Bool = true, hideToolBar: Bool = false) {
        self.init(aRequest: URLRequest(url: pageURL), sharingEnabled: sharingEnabled, hideToolBar: hideToolBar)
    }

    public convenience init(aRequest: URLRequest, sharingEnabled: Bool = true, hideToolBar: Bool = false) {
        self.init()

        self.sharingEnabled = sharingEnabled
        self.request = aRequest
        self.hideToolBar = hideToolBar
    }

    deinit {
        webView.stopLoading()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        webView.navigationDelegate = nil
    }

    func loadRequest(_ request: URLRequest) {
        webView.load(request)
    }

    ////////////////////////////////////////////////
    // View Lifecycle
    override public func loadView() {
        view = webView
        loadRequest(request)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        assert(self.navigationController != nil, "SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.")

        updateToolbarItems()
        navBarTitle = UILabel()
        navBarTitle.backgroundColor = .clear
        if presentingViewController == nil {
            if let titleAttributes = navigationController?.navigationBar.titleTextAttributes as [NSAttributedString.Key: Any]? {
                navBarTitle.textColor = titleAttributes[NSAttributedString.Key.foregroundColor] as? UIColor
            }
        } else {
            navBarTitle.textColor = self.titleColor
        }

        navBarTitle.shadowOffset = CGSize(width: 0, height: 1)
        navBarTitle.font = UIFont(name: "HelveticaNeue-Medium", size: 17.0)
        navBarTitle.textAlignment = .center
        navigationItem.titleView = navBarTitle

        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            navigationController?.setToolbarHidden(hideToolBar, animated: false)
        case .pad:
            navigationController?.setToolbarHidden(true, animated: true)
        default:
            break
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    ////////////////////////////////////////////////
    // Toolbar
    func updateToolbarItems() {
        guard !hideToolBar else { return }

        backBarButtonItem.isEnabled = webView.canGoBack
        forwardBarButtonItem.isEnabled = webView.canGoForward

        let refreshStopBarButtonItem = webView.isLoading ? stopBarButtonItem : refreshBarButtonItem
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        if UIDevice.current.userInterfaceIdiom == .pad {
            let toolbarWidth: CGFloat = 250.0
            fixedSpace.width = 35.0

            let items = sharingEnabled ? [fixedSpace, refreshStopBarButtonItem, fixedSpace, backBarButtonItem, fixedSpace, forwardBarButtonItem, fixedSpace, actionBarButtonItem] : [fixedSpace, refreshStopBarButtonItem, fixedSpace, backBarButtonItem, fixedSpace, forwardBarButtonItem]

            let toolbar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: toolbarWidth, height: 44.0))
            if !closing {
                toolbar.items = items

                if presentingViewController == nil {
                    toolbar.barTintColor = navigationController?.navigationBar.barTintColor
                } else {
                    toolbar.barStyle = navigationController?.navigationBar.barStyle ?? .default
                }

                toolbar.tintColor = navigationController?.navigationBar.tintColor
            }

            navigationItem.rightBarButtonItems = items.reversed()
        } else {
            let items: NSArray = sharingEnabled ? [fixedSpace, backBarButtonItem, flexibleSpace, forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, flexibleSpace, actionBarButtonItem, fixedSpace] : [fixedSpace, backBarButtonItem, flexibleSpace, forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, fixedSpace]

            if let navigationController = navigationController, !closing {
                if presentingViewController == nil {
                    navigationController.toolbar.barTintColor = navigationController.navigationBar.barTintColor
                } else {
                    navigationController.toolbar.barStyle = navigationController.navigationBar.barStyle
                }

                navigationController.toolbar.tintColor = navigationController.navigationBar.tintColor
                toolbarItems = items as? [UIBarButtonItem]
            }
        }
    }

    ////////////////////////////////////////////////
    // Target Actions
    @objc func goBackTapped(_ sender: UIBarButtonItem) {
        webView.goBack()
    }

    @objc func goForwardTapped(_ sender: UIBarButtonItem) {
        webView.goForward()
    }

    @objc func reloadTapped(_ sender: UIBarButtonItem) {
        webView.reload()
    }

    @objc func stopTapped(_ sender: UIBarButtonItem) {
        webView.stopLoading()
        updateToolbarItems()
    }

    @objc func actionButtonTapped(_ sender: AnyObject) {
        if let url = (webView.url != nil) ? webView.url : request.url {
            let activities = [SwiftWebVCActivitySafari(), SwiftWebVCActivityChrome()]

            if url.absoluteString.hasPrefix("file:///") {
                let dc = UIDocumentInteractionController(url: url)
                dc.presentOptionsMenu(from: view.bounds, in: view, animated: true)
            } else {
                let activityController = UIActivityViewController(activityItems: [url], applicationActivities: activities)

                if floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && UIDevice.current.userInterfaceIdiom == .pad {
                    let ctrl = activityController.popoverPresentationController
                    ctrl?.sourceView = view
                    ctrl?.barButtonItem = sender as? UIBarButtonItem
                }

                present(activityController, animated: true, completion: nil)
            }
        }
    }

    ////////////////////////////////////////////////

    @objc func doneButtonTapped() {
        closing = true
        UINavigationBar.appearance().barStyle = storedStatusColor
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Class Methods
    /// Helper function to get image within SwiftWebVCResources bundle
    ///
    /// - parameter named: The name of the image in the SwiftWebVCResources bundle
    class func bundledImage(named: String) -> UIImage? {
        let image = UIImage(named: named)
        if image == nil {
            return UIImage(named: named, in: Bundle(for: SwiftWebVC.self), compatibleWith: nil)
        }
        
        return image
    }
}

extension SwiftWebVC: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        delegate?.didStartLoading()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        updateToolbarItems()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        delegate?.didFinishLoading(success: true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false

        if let title = self.title {
            navBarTitle.text = title
            navBarTitle.sizeToFit()
            updateToolbarItems()
        } else {
            webView.evaluateJavaScript("document.title", completionHandler: { [weak self] (response, _) in
                self?.navBarTitle.text = response as? String ?? ""
                self?.navBarTitle.sizeToFit()
                self?.updateToolbarItems()
            })
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.didFinishLoading(success: false)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        updateToolbarItems()
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if navigationAction.targetFrame == nil {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }

        let hostAddress = navigationAction.request.url?.host
        // To connnect app store
        if hostAddress == "itunes.apple.com" {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
                decisionHandler(.cancel)
                return
            }
        }

        let urlElements = url.absoluteString.components(separatedBy: ":")

        switch urlElements.first {
        case "tel":
            openCustomApp(urlScheme: "telprompt://", additional_info: urlElements[1])
            decisionHandler(.cancel)
        case "sms":
            openCustomApp(urlScheme: "sms://", additional_info: urlElements[1])
            decisionHandler(.cancel)
        case "mailto":
            openCustomApp(urlScheme: "mailto://", additional_info: urlElements[1])
            decisionHandler(.cancel)
        default:
            break
        }

        decisionHandler(.allow)
    }

    func openCustomApp(urlScheme: String, additional_info:String){
        if let requestUrl: URL = URL(string:"\(urlScheme)"+"\(additional_info)") {
            let application = UIApplication.shared

            if application.canOpenURL(requestUrl) {
                application.openURL(requestUrl)
            }
        }
    }
}
