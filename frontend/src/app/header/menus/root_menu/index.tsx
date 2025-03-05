import Link from "next/link";
import Image from "next/image";

export default () => {
  return (
    <Link href="/" className="flex bg-gray-100 mt-1 ml-1 p-1 rounded-md items-center justify-center">
      <Image alt="dexterity" src="/icon.svg" width={32} height={32} />
      <span className="font-black">Dexterity</span>
    </Link>
  );
}
