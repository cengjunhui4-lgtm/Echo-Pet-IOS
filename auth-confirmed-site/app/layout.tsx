import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Echo Pet Email Verified",
  description: "Your Echo Pet account email has been verified.",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-Hans">
      <body>{children}</body>
    </html>
  );
}
