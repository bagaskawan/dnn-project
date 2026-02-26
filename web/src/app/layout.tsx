import { Montserrat } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "../components/theme-provider";

const montserrat = Montserrat({ subsets: ["latin"] });

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
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${montserrat.className} text-app-text bg-app-bg antialiased`}
      >
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
