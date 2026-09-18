export function Logo() {
  return (
    <svg className="logo" width="32" height="32" viewBox="0 0 64 64" aria-hidden="true" focusable="false">
      <rect width="64" height="64" rx="14" fill="#141414" />
      <rect x="15" y="14" width="26" height="36" rx="6" fill="#2A2A2A" transform="rotate(-12 28 32)" />
      <rect x="23" y="13" width="26" height="36" rx="6" fill="#1FA2FF" transform="rotate(10 36 31)" />
      <path
        d="M32 31.5l3.5 3.5 7-7.5"
        fill="none"
        stroke="#0A0A0A"
        strokeWidth="3.6"
        strokeLinecap="round"
        strokeLinejoin="round"
        transform="rotate(10 36 31)"
      />
    </svg>
  );
}
