import EnGardeIcon from "@/assets/EnGardeIcon.svg";

export default function EnGardeFooter(): JSX.Element {
  return (
    <div className="fixed bottom-0 left-0 z-50 flex items-center gap-2 px-4 py-2 bg-background/80 backdrop-blur-sm border-t">
      <span className="text-sm text-muted-foreground flex items-center gap-1.5">
        Made by
        <img src={EnGardeIcon} alt="EnGarde" className="h-5 w-5 inline-block" />
        with ❤️
      </span>
    </div>
  );
}
