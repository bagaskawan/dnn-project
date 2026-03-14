"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import { usePathname, useSearchParams } from "next/navigation";

/**
 * TopLoader — garis loading tipis di paling atas halaman
 * yang muncul saat navigasi antar halaman.
 */
export function TopLoader() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const prevPathRef = useRef(pathname + searchParams.toString());

  const startLoading = useCallback(() => {
    setLoading(true);
    setProgress(0);

    // Simulate incremental progress
    if (timerRef.current) clearInterval(timerRef.current);
    let current = 0;
    timerRef.current = setInterval(() => {
      current += Math.random() * 15 + 5;
      if (current >= 90) {
        current = 90; // Cap at 90% until complete
        if (timerRef.current) clearInterval(timerRef.current);
      }
      setProgress(current);
    }, 150);
  }, []);

  const completeLoading = useCallback(() => {
    if (timerRef.current) clearInterval(timerRef.current);
    setProgress(100);
    setTimeout(() => {
      setLoading(false);
      setProgress(0);
    }, 300);
  }, []);

  useEffect(() => {
    const currentPath = pathname + searchParams.toString();
    if (prevPathRef.current !== currentPath) {
      // Route changed — show loading then complete
      startLoading();
      // In App Router, the new page is already rendered when
      // pathname changes, so we can complete immediately
      const timer = setTimeout(() => {
        completeLoading();
      }, 200);
      prevPathRef.current = currentPath;
      return () => clearTimeout(timer);
    }
  }, [pathname, searchParams, startLoading, completeLoading]);

  // Intercept link clicks to start loading before navigation
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const anchor = target.closest("a");
      if (!anchor) return;

      const href = anchor.getAttribute("href");
      if (
        !href ||
        href.startsWith("#") ||
        href.startsWith("http") ||
        href.startsWith("mailto:")
      )
        return;

      const currentPath = pathname + searchParams.toString();
      if (href !== currentPath && href !== pathname) {
        startLoading();
      }
    };

    document.addEventListener("click", handleClick, true);
    return () => document.removeEventListener("click", handleClick, true);
  }, [pathname, searchParams, startLoading]);

  if (!loading && progress === 0) return null;

  return (
    <div
      className="fixed top-0 left-0 right-0 z-[9999] pointer-events-none"
      style={{ height: "3px" }}
    >
      <div
        className="h-full bg-gradient-to-r from-amber-500 via-orange-500 to-amber-400"
        style={{
          width: `${progress}%`,
          transition:
            progress === 100
              ? "width 200ms ease-out, opacity 300ms ease-out 100ms"
              : "width 300ms ease-out",
          opacity: progress === 100 ? 0 : 1,
          boxShadow: "0 0 8px rgba(245, 241, 11, 0.6)",
        }}
      />
    </div>
  );
}
