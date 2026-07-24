import GoogleMobileAds
import UIKit

/// Native Ad Factory for Edu-Tech iOS.
///
/// Builds the native ad view programmatically — no XIB dependency.
class EduTechNativeAdFactory: FLTNativeAdFactory {

    func createNativeAd(
        _ nativeAd: GADNativeAd,
        customOptions: [AnyHashable: Any]? = nil
    ) -> GADNativeAdView? {
        let nativeAdView = GADNativeAdView()
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.backgroundColor = .white
        nativeAdView.layer.cornerRadius = 8
        nativeAdView.layer.borderWidth = 1
        nativeAdView.layer.borderColor = UIColor(white: 0.88, alpha: 1).cgColor
        nativeAdView.clipsToBounds = true

        // ----- Attribution -----
        let attributionLabel = UILabel()
        attributionLabel.text = "Ad"
        attributionLabel.font = UIFont.boldSystemFont(ofSize: 10)
        attributionLabel.textColor = UIColor(red: 1, green: 0.6, blue: 0, alpha: 1)
        attributionLabel.translatesAutoresizingMaskIntoConstraints = false

        // ----- Icon -----
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        if let icon = nativeAd.icon {
            iconView.image = icon.image
        }
        nativeAdView.iconView = iconView

        // ----- Headline -----
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headlineLabel.textColor = UIColor(white: 0.13, alpha: 1)
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.text = nativeAd.headline
        nativeAdView.headlineView = headlineLabel

        // ----- Advertiser -----
        let advertiserLabel = UILabel()
        advertiserLabel.font = UIFont.systemFont(ofSize: 12)
        advertiserLabel.textColor = UIColor(white: 0.46, alpha: 1)
        advertiserLabel.numberOfLines = 1
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        if let advertiser = nativeAd.advertiser {
            advertiserLabel.text = advertiser
        }
        nativeAdView.advertiserView = advertiserLabel

        // ----- Star Rating -----
        let starLabel = UILabel()
        starLabel.font = UIFont.systemFont(ofSize: 12)
        starLabel.textColor = UIColor(white: 0.46, alpha: 1)
        starLabel.translatesAutoresizingMaskIntoConstraints = false
        if let rating = nativeAd.starRating {
            starLabel.text = "★ \(rating.doubleValue)"
            starLabel.isHidden = false
        } else {
            starLabel.isHidden = true
        }
        nativeAdView.starRatingView = starLabel

        // ----- Media -----
        let mediaView = GADMediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.mediaContent = nativeAd.mediaContent
        nativeAdView.mediaView = mediaView

        // ----- Body -----
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 14)
        bodyLabel.textColor = UIColor(white: 0.26, alpha: 1)
        bodyLabel.numberOfLines = 3
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        if let body = nativeAd.body {
            bodyLabel.text = body
        }
        nativeAdView.bodyView = bodyLabel

        // ----- Store -----
        let storeLabel = UILabel()
        storeLabel.font = UIFont.systemFont(ofSize: 12)
        storeLabel.textColor = UIColor(white: 0.46, alpha: 1)
        storeLabel.translatesAutoresizingMaskIntoConstraints = false
        if let store = nativeAd.store {
            storeLabel.text = store
        }
        nativeAdView.storeView = storeLabel

        // ----- Price -----
        let priceLabel = UILabel()
        priceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        priceLabel.textColor = UIColor(red: 0.3, green: 0.69, blue: 0.31, alpha: 1)
        priceLabel.textAlignment = .right
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        if let price = nativeAd.price {
            priceLabel.text = price
        }
        nativeAdView.priceView = priceLabel

        // ----- CTA -----
        let ctaButton = UIButton(type: .system)
        ctaButton.backgroundColor = UIColor(red: 0.08, green: 0.4, blue: 0.75, alpha: 1)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        ctaButton.layer.cornerRadius = 6
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        if let cta = nativeAd.callToAction {
            ctaButton.setTitle(cta, for: .normal)
        }
        nativeAdView.callToActionView = ctaButton

        // ----- Layout -----

        nativeAdView.addSubview(attributionLabel)
        nativeAdView.addSubview(iconView)
        nativeAdView.addSubview(headlineLabel)
        nativeAdView.addSubview(advertiserLabel)
        nativeAdView.addSubview(starLabel)
        nativeAdView.addSubview(mediaView)
        nativeAdView.addSubview(bodyLabel)
        nativeAdView.addSubview(storeLabel)
        nativeAdView.addSubview(priceLabel)
        nativeAdView.addSubview(ctaButton)

        NSLayoutConstraint.activate([
            // Attribution
            attributionLabel.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 12),
            attributionLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),

            // Icon
            iconView.topAnchor.constraint(equalTo: attributionLabel.bottomAnchor, constant: 8),
            iconView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            // Headline
            headlineLabel.topAnchor.constraint(equalTo: iconView.topAnchor),
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            headlineLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),

            // Advertiser
            advertiserLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 2),
            advertiserLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            advertiserLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),

            // Star
            starLabel.topAnchor.constraint(equalTo: advertiserLabel.bottomAnchor, constant: 2),
            starLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),

            // Media
            mediaView.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            mediaView.heightAnchor.constraint(equalToConstant: 160),

            // Body
            bodyLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),

            // Store
            storeLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 6),
            storeLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),

            // Price
            priceLabel.centerYAnchor.constraint(equalTo: storeLabel.centerYAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: storeLabel.trailingAnchor, constant: 8),
            priceLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),

            // CTA
            ctaButton.topAnchor.constraint(equalTo: storeLabel.bottomAnchor, constant: 8),
            ctaButton.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            ctaButton.heightAnchor.constraint(equalToConstant: 38),
            ctaButton.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -12),
        ])

        nativeAdView.nativeAd = nativeAd
        return nativeAdView
    }
}
