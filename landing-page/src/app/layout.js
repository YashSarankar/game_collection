import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
    title: "SnapPlay | Offline Multiplayer Game Collection",
    description: "Play 30+ premium mini-games without internet. Challenge friends via Bluetooth or pass-and-play.",
};

export default function RootLayout({ children }) {
    return (
        <html lang="en">
            <body className={inter.className}>{children}</body>
        </html>
    );
}
