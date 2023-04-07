import { Link } from "wouter";
import { Participant } from "./App";

export interface ScoreboardProps {
  participants: Map<number, Participant>;
}

export const Scoreboard = (props: ScoreboardProps) => {
  const sorter = (a: Participant, b: Participant) => {
    return b.score.pointsWon - a.score.pointsWon;
  };
  const header = <div className="grid grid-cols-11 font-semibold pb-2">
    <div></div>
    <div className="col-span-2">Name</div>
    <div className="col-span-2">Points Won</div>
    <div className="col-span-2">Lost</div>
    <div className="col-span-2">Remaining</div>
    <div className="col-span-2">Average</div>
  </div>
  const rows = Array.from(props.participants.values()).sort(sorter).map((val: Participant, idx: number) => {
    return <div key={val.name} className="grid grid-cols-11 odd:bg-white even:bg-slate-50">
      <div>
        <span>{idx + 1}. </span>
      </div>
      <div className="col-span-2">
        <span className="text-sm hover:text-orange-500 cursor-pointer p-1"><Link href={"/participants/" + val.id}>{val.name}</Link></span>
      </div>
      <div className="col-span-2 text-sm p-1">{val.score.pointsWon}</div>
      <div className="col-span-2 text-sm">{val.score.pointsLost}</div>
      <div className="col-span-2 text-sm">{val.score.pointsRemaining}</div>
      <div className="col-span-2 text-sm">{val.score.scoringAvg?.toFixed(2)}</div>
    </div>
  });

  return <div className="gap-2 pl-6 pr-6 container w-3/5">
    <div className="bg-slate-50 rounded-lg pl-3 pt-12">
      {header}
      {rows}
    </div>
  </div>;
};