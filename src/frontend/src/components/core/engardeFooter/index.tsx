import EnGardeLogo from "@/assets/EnGardeLogo.png";

export default function EnGardeFooter(): JSX.Element {
  return (
    <div className="fixed bottom-0 left-0 z-50 flex items-center gap-2 px-4 py-2 bg-background/80 backdrop-blur-sm border-t">
      <img src={EnGardeLogo} alt="EnGarde" className="h-6 w-6" />
      <span className="text-sm text-muted-foreground">
        From EnGarde with Love ❤️
      </span>
    </div>
  );
}
