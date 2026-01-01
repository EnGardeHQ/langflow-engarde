import EnGardeIcon from "@/assets/EnGardeIcon.svg";

export default function EnGardeFooter(): JSX.Element {
  return (
    <div className="fixed bottom-0 left-0 z-50 flex items-center gap-2 px-4 py-2 bg-background/80 backdrop-blur-sm border-t">
      <span className="flex items-center gap-1 text-sm text-muted-foreground mr-2">
        Powered by EnGarde
      </span>
      <span className="flex items-center gap-1 text-sm text-muted-foreground">
        From <img src={EnGardeIcon} alt="EnGarde" className="h-4 w-4 inline-block" /> with ❤️
      </span>
    </div>
  );
}
