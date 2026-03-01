declare global {
  type Lang = "en";

  type Theme = "dark" | "light";

  type DataType = { value: string | Record<string, unknown>; label: string };
}

export {};
