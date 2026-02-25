import { Montserrat } from 'next/font/google';
import "./globals.css";

const montserrat = Montserrat({ subsets: ['latin'] });

// 🚀 APP ROUTER: Root layout (Provider pembungkus keseluruhan app)
export const metadata = {
  title: "Admin Dashboard",
  description: "Generated app",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={`${montserrat.className} text-app-text bg-app-bg antialiased`}>{children}</body>
    </html>
  );
}