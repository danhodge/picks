import { Link, useLocation } from "wouter";
import { Participant, Season } from "./App";
import { useEffect } from "react";

export interface ScoreboardProps {
  participants: Map<number, Participant>;
  season: Season;
}

export const Scoreboard = (props: ScoreboardProps) => {
  const [_, setLocation] = useLocation();

  useEffect(() => {
    // all requests for unknown paths get sent to Scoreboard so update 
    // the location on load to clear out any bad state
    setLocation(`/${props.season.path}`);
  });

  const sorter = (a: Participant, b: Participant) => {
    return b.score.pointsWon - a.score.pointsWon;
  };
  const header = <>
    <div className="col-span-4 font-semibold pb-2">Name</div>
    <div className="col-span-2 font-semibold pb-2">Points Won</div>
    <div className="col-span-2 font-semibold pb-2">Lost</div>
    <div className="col-span-2 font-semibold pb-2">Remaining</div>
    <div className="col-span-2 font-semibold pb-2">Average</div>
  </>
  const rows = Array.from(props.participants.values()).sort(sorter).map((val: Participant, idx: number) => {
    return <>
      <div className="col-span-4 grid grid-cols-9">
        <div className="text-sm">{idx + 1}.</div>
        <div className="text-sm hover:text-orange-500 cursor-pointer col-span-8"><Link href={"/" + props.season.path + "/participants/" + val.id}>{val.name}</Link></div>
      </div>
      <div className="col-span-2 text-sm p-1">{val.score.pointsWon}</div>
      <div className="col-span-2 text-sm">{val.score.pointsLost}</div>
      <div className="col-span-2 text-sm">{val.score.pointsRemaining}</div>
      <div className="col-span-2 text-sm">{val.score.scoringAvg?.toFixed(2)}</div>
    </>
  });

  return <div className="gap-2 pl-6 pr-6 container w-3/5">
    <div className="bg-slate-50 rounded-lg pl-3 pt-12">
      <div className="grid grid-cols-12 odd:bg-white even:bg-slate-50">
        {header}
        {rows}
      </div>
    </div>
  </div>;
};