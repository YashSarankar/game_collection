import React from 'react'

export default function PrivacyPolicy() {
    return (
        <div className="min-h-screen bg-slate-900 text-slate-300 font-sans p-8 md:p-24">
            <div className="max-w-4xl mx-auto bg-slate-800/50 p-8 rounded-3xl border border-white/10">
                <h1 className="text-4xl font-extrabold text-white mb-8">Privacy Policy</h1>

                <section className="mb-8">
                    <h2 className="text-2xl font-bold text-white mb-4">1. Introduction</h2>
                    <p className="leading-relaxed">
                        Sarankar Developers ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy applies to our mobile applications, including <strong>SnapPlay</strong>, <strong>Amozea</strong>, and any other apps published by us on the Google Play Store.
                        By using our applications, you signify that you have read, understood, and agree to our collection, storage, use, and disclosure of your personal information as described in this Privacy Policy.
                    </p>
                </section>

                <section className="mb-8">
                    <h2 className="text-2xl font-bold text-white mb-4">2. Information Collection</h2>
                    <p className="leading-relaxed mb-4">
                        <strong>Personal Information:</strong> We do not collect any personally identifiable information (PII) such as your name, address, or phone number unless you explicitly provide it to us for support purposes.
                    </p>
                    <p className="leading-relaxed">
                        <strong>Device Information:</strong> We may collect non-personal information about the device you use to access our apps, including device model, operating system version, and unique device identifiers (like Android Advertising ID). This is primarily used for ad delivery and analytics.
                    </p>
                </section>

                <section className="mb-8">
                    <h2 className="text-2xl font-bold text-white mb-4">3. Use of Information</h2>
                    <p className="leading-relaxed">
                        We use the information we collect to:
                    </p>
                    <ul className="list-disc ml-6 mt-2 space-y-2">
                        <li>Provide and maintain our applications.</li>
                        <li>Show relevant advertisements via Google AdMob.</li>
                        <li>Analyze usage patterns to improve the user experience.</li>
                        <li>Communicate with you regarding support requests.</li>
                    </ul>
                </section>

                <section className="mb-8">
                    <h2 className="text-2xl font-bold text-white mb-4">4. Third-Party Services</h2>
                    <p className="leading-relaxed mb-4">
                        Our apps use third-party services that may collect information used to identify you:
                    </p>
                    <div className="bg-slate-900/50 p-4 rounded-xl border border-white/5">
                        <ul className="list-disc ml-6 space-y-2">
                            <li>
                                <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer" className="text-orange-400 hover:underline">
                                    Google Play Services
                                </a>
                            </li>
                            <li>
                                <a href="https://support.google.com/admob/answer/6128543?hl=en" target="_blank" rel="noopener noreferrer" className="text-orange-400 hover:underline">
                                    AdMob
                                </a>
                            </li>
                        </ul>
                    </div>
                </section>

                <section className="mb-8">
                    <h2 className="text-2xl font-bold text-white mb-4">5. Data Retention</h2>
                    <p className="leading-relaxed">
                        We do not store your personal data on our servers. Any app-specific progress, settings, or favorites (like saved wallpapers) are stored locally on your device.
                    </p>
                </section>

                <section className="mb-8">
                    <h2 className="text-2xl font-bold text-white mb-4">6. Contact Us</h2>
                    <p className="leading-relaxed">
                        If you have any questions about this Privacy Policy, please contact us at:
                        <br />
                        <span className="text-orange-400 font-bold">support@sarankar.com</span>
                    </p>
                </section>

                <footer className="mt-12 pt-8 border-t border-white/10 text-sm text-slate-500">
                    Last updated: February 16, 2026
                </footer>
            </div>
        </div>
    )
}
