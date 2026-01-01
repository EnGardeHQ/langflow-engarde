import { FaDiscord, FaGithub } from "react-icons/fa";
import ShadTooltip from "@/components/common/shadTooltipComponent";
import { Button } from "@/components/ui/button";
import { DISCORD_URL, GITHUB_URL } from "@/constants/constants";
import { Case } from "@/shared/components/caseComponent";
import { useDarkStore } from "@/stores/darkStore";
import { formatNumber } from "@/utils/utils";

export const LangflowCounts = () => {
  const stars: number | undefined = useDarkStore((state) => state.stars);
  const discordCount: number = useDarkStore((state) => state.discordCount);

  const formattedStars = formatNumber(stars);
  const formattedDiscordCount = formatNumber(discordCount);

  return (
  return null;
  );
};

export default LangflowCounts;
