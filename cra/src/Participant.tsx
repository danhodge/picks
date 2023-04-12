import { Data, Game, Participant, Pick } from "./App";
import { Link } from "wouter";

export interface ParticipantComponentProps {
  data: Data;
  participant: Participant;
}

export const ParticipantComponent = (props: ParticipantComponentProps) => {
  const rowBg = ["bg-slate-50", "bg-white"];
  var prevDate: string = "";
  const results = Array.from(props.participant.picks.entries()).map((val: [number, Pick], idx: number) => {
    const [_, pick] = val;
    const outcome = props.data.results.get(pick.game.id);
    const date = new Date(Date.parse(pick.game.time)).toLocaleDateString("en-US", { month: "short", day: "numeric" });
    var borderStyle = "";
    if (prevDate !== "" && date !== prevDate) {
      prevDate = date;
      borderStyle = " border-t-2 border-slate-400 pt-4";
    } else if (prevDate === "") {
      prevDate = date;
    }

    return <>
      <div className={rowBg[idx % 2] + borderStyle + " text-sm p-1"}>{date}</div>
      <div className={rowBg[idx % 2] + borderStyle + " col-span-3 text-sm hover:text-orange-500 cursor-pointer p-1"}><Link href={"/" + props.data.season.path + "/games/" + pick.game.id}>{pick.game.name}</Link></div>
      {/* TOOD: show team (points) for games that have not finished yet */}
      <div className={rowBg[idx % 2] + borderStyle + " col-span-2 text-sm p-1"}>{pick.team.name}</div>
      <div className={rowBg[idx % 2] + borderStyle + " text-sm p-1"}></div>
      <div className={rowBg[idx % 2] + borderStyle + " text-sm font-thin p-1 grid grid-cols-4"}>
        <div className="text-right">{(outcome?.pointsAwardedTo === pick.team) ? "" : "-"}</div>
        <div className="text-left">{pick.points}</div>
        <div className="col-span-2"></div>
      </div>
      <div className={rowBg[idx % 2] + borderStyle + " text-sm p-1"}>{pick.totalPoints}</div>
      <div className={rowBg[idx % 2] + borderStyle + " text-sm p-1"}>{place(props.data.participants, props.participant, pick.game, pick.totalPoints)}</div>
    </>;
  });
  return <div className="gap-2 pl-6 pr-6 container w-4/5">
    <div className="bg-slate-50 rounded-lg pl-3 pt-12">
      <div className="pb-4 pt-2 font-semibold">{props.participant.name}</div>
      <div className="pt-2 grid grid-cols-10 w-4/5">
        <div className="font-semibold">Date</div>
        <div className="font-semibold col-span-3">Game</div>
        <div className="font-semibold col-span-2">Choice</div>
        <div></div>
        <div className="font-semibold">Change</div>
        <div className="font-semibold">Total</div>
        <div className="font-semibold">Place</div>
        {results}
      </div>
    </div>
  </div >;
};

interface ParticipantPoints {
  participant: Participant;
  points: number;
};

const place = (participants: Map<number, Participant>, participant: Participant, game: Game, totalPoints: number) => {
  const sorter = (a: ParticipantPoints, b: ParticipantPoints) => {
    const diff = b.points - a.points;
    if (diff === 0) {
      return a.participant.name < b.participant.name ? -1 : 1;
    }
    return diff;
  };

  const results = Array.from(participants.values()).map((val: Participant) => {
    const pick = val.picks.get(game.id);
    if (pick) {
      // TODO: should also take points lost into account
      return { participant: val, points: pick.totalPoints };
    } else {
      return { participant: val, points: 0 };
    }
  }).sort(sorter);

  return results.findIndex((val: ParticipantPoints) => val.participant === participant) + 1;
};

