import Link from "next/link";
import Image from "next/image";

export default function RootMenu() {
  return (
    <Link href="/" className="flex bg-[var(--menu-button-background)] mt-1 ml-1 p-1 rounded-md items-center justify-center">
      <Image className="dark:invert" alt="dexterity" src="/icon.svg" width={32} height={32} />
      <span className="font-black">Dexterity</span>
    </Link>
  );
}
