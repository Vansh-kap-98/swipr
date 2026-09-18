'use client';

import { useEffect, useRef, useState } from 'react';

export function CopyButton({ value }: { value: string }) {
  const [label, setLabel] = useState('Copy');
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);

  useEffect(() => () => clearTimeout(timer.current), []);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(value);
      setLabel('Copied');
    } catch {
      setLabel('Select & copy');
    }
    clearTimeout(timer.current);
    timer.current = setTimeout(() => setLabel('Copy'), 2000);
  };

  return (
    <button className="btn btn--ghost btn--small" type="button" onClick={copy}>
      {label}
    </button>
  );
}
