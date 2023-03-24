import { Participant } from "./App";

export interface ScoreboardProps {
    participants: Map<number, Participant>;
}

export const Scoreboard = (props: ScoreboardProps) => {
    const sorter = (a: Participant, b: Participant) => {
        return b.score.pointsWon - a.score.pointsWon;
    };
    const header = <div className="grid grid-cols-11 font-semibold">
        <div className="col-span-3">Name</div>
        <div className="col-span-2">Points Won</div>
        <div className="col-span-2">Points Lost</div>
        <div className="col-span-2">Points Remaining</div>
        <div className="col-span-2">Scoring Average</div>
    </div>
    const rows = Array.from(props.participants.values()).sort(sorter).map((val: Participant, idx: number) => {
        return <div key={val.name} className="grid grid-cols-11">
            <div className="col-span-3">{idx + 1}. {val.name}</div>
            <div className="col-span-2">{val.score.pointsWon}</div>
            <div className="col-span-2">{val.score.pointsLost}</div>
            <div className="col-span-2">{val.score.pointsRemaining}</div>
            <div className="col-span-2">{val.score.scoringAvg}</div>
        </div>
    });

    return <div className="bg-gray-50 gap-2 pl-6 pr-6 pt-4 w-3/5">{header}{rows}</div>;
};