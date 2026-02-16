'use client'

import React from 'react'
import { motion } from 'framer-motion'
import { Gamepad2, Users, Download, Trophy, Zap, ChevronRight } from 'lucide-react'

export default function SnapPlayLanding() {
    return (
        <div className="min-h-screen bg-slate-900 text-white font-sans selection:bg-orange-500 selection:text-white">
            {/* Navbar */}
            <nav className="fixed top-0 w-full z-50 backdrop-blur-md bg-slate-900/80 border-b border-white/10">
                <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-lg bg-orange-500 flex items-center justify-center">
                            <Gamepad2 className="w-5 h-5 text-white" />
                        </div>
                        <span className="text-xl font-bold tracking-tight">SnapPlay</span>
                    </div>
                    <div className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-300">
                        <a href="#features" className="hover:text-white transition-colors">Features</a>
                        <a href="https://sarankar.com" className="hover:text-white transition-colors">Developer</a>
                    </div>
                    <a
                        href="https://play.google.com/store/apps/details?id=com.snapplay.offline.games"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="bg-white text-slate-900 px-5 py-2 rounded-full font-bold text-sm hover:bg-slate-200 transition-colors"
                    >
                        Download
                    </a>
                </div>
            </nav>

            {/* Hero Section */}
            <header className="pt-32 pb-20 px-6 relative overflow-hidden">
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[500px] bg-orange-500/20 blur-[120px] rounded-full pointer-events-none" />

                <div className="max-w-4xl mx-auto text-center relative z-10">
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.5 }}
                    >
                        <span className="inline-block py-1 px-3 rounded-full bg-white/5 border border-white/10 text-orange-400 text-xs font-bold tracking-wider mb-6">
                            OFFLINE MULTIPLAYER GAMES
                        </span>
                        <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight mb-6 leading-tight">
                            Your Ultimate <span className="text-transparent bg-clip-text bg-gradient-to-r from-orange-400 to-amber-600">Offline Game</span> Collection
                        </h1>
                        <p className="text-lg md:text-xl text-slate-400 mb-10 max-w-2xl mx-auto leading-relaxed">
                            Play 30+ premium mini-games without internet. Challenge friends via Bluetooth or pass-and-play. No Wi-Fi? No Problem.
                        </p>

                        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                            <a
                                href="https://play.google.com/store/apps/details?id=com.snapplay.offline.games"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center gap-2 bg-orange-600 hover:bg-orange-700 text-white px-8 py-4 rounded-xl font-bold text-lg transition-transform hover:scale-105 shadow-lg shadow-orange-500/20"
                            >
                                <Download className="w-5 h-5" />
                                Get on Google Play
                            </a>
                            <a
                                href="#features"
                                className="flex items-center gap-2 bg-white/5 hover:bg-white/10 text-white px-8 py-4 rounded-xl font-bold text-lg transition-colors border border-white/10"
                            >
                                Learn More
                                <ChevronRight className="w-5 h-5" />
                            </a>
                        </div>
                    </motion.div>
                </div>
            </header>

            {/* Features Grid */}
            <section id="features" className="py-20 bg-slate-800/50">
                <div className="max-w-6xl mx-auto px-6">
                    <div className="grid md:grid-cols-3 gap-8">
                        {[
                            {
                                icon: <Zap className="w-6 h-6 text-yellow-400" />,
                                title: "Zero Internet Needed",
                                desc: "Every game works 100% offline. Perfect for flights, road trips, or when you're out of data."
                            },
                            {
                                icon: <Users className="w-6 h-6 text-blue-400" />,
                                title: "Multiplayer Madness",
                                desc: "Challenge friends on the same device (Pass & Play) or connect via Bluetooth for local battles."
                            },
                            {
                                icon: <Trophy className="w-6 h-6 text-purple-400" />,
                                title: "Global Leaderboards",
                                desc: "Climb the ranks and prove your skills in daily challenges."
                            }
                        ].map((feature, i) => (
                            <div key={i} className="bg-slate-900 p-8 rounded-3xl border border-white/10 hover:border-white/20 transition-colors">
                                <div className="w-12 h-12 bg-white/5 rounded-2xl flex items-center justify-center mb-6">
                                    {feature.icon}
                                </div>
                                <h3 className="text-xl font-bold mb-3">{feature.title}</h3>
                                <p className="text-slate-400 leading-relaxed">{feature.desc}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer className="py-12 border-t border-white/10 bg-slate-950">
                <div className="max-w-6xl mx-auto px-6 flex flex-col md:flex-row items-center justify-between gap-6">
                    <div className="flex items-center gap-2">
                        <div className="w-6 h-6 rounded bg-orange-500 flex items-center justify-center">
                            <Gamepad2 className="w-3 h-3 text-white" />
                        </div>
                        <span className="font-bold text-slate-300">SnapPlay</span>
                    </div>
                    <div className="flex items-center gap-6 text-sm text-slate-500">
                        <a href="https://sarankar.com" className="hover:text-white transition-colors">Developer Website</a>
                        <a href="/privacy" className="hover:text-white transition-colors">Privacy Policy</a>
                        <a href="mailto:support@sarankar.com" className="hover:text-white transition-colors">Support</a>
                    </div>
                    <p className="text-sm text-slate-600">
                        &copy; 2026 SnapPlay.
                    </p>
                </div>
            </footer>
        </div>
    )
}
