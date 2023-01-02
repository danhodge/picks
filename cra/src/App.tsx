import { timeStamp } from 'console';
import React, { useEffect, useState } from 'react';
import { QueryClient, QueryClientProvider, useQuery } from 'react-query';
import internal from 'stream';
import { TemplateExpression, textChangeRangeIsUnchanged } from 'typescript';
import './App.css';
import GameComponent from './Game';

/*export interface TeamWithScore {
  name: string;
  score?: number;
}

const loadTeamWithScore = (data: any) => {
  const team: TeamWithScore = { name: data.name };
  if (data.score !== "") {
    team.score = parseInt(data.score);
  }

  return team;
};*/

export interface Game {
  name: string;
  location: string;
  time: string;
  visitor: Team;
  home: Team;
  scores: Array<FinalScore>;
  totalPoints: number;
  totalPointsWon?: number;
};

export interface Team {
  name: string;
};

export interface FinalScore {
  game: Game;
  team: Team;
  score: number;
};

export interface Pick {
  game: Game;
  team: Team;
  points: number;
};

export interface Participant {
  name: string;
  tieBreaker: number;
  picks: Array<Pick>;
}

export interface Data {
  games: Array<Game>;
  participants: Array<Participant>;
}

const unknownGame = () => {
  return {} as Game;
}

const loadGame = (data: any) => {
  const game: Game = {
    name: data.name,
    location: data.location,
    time: data.time,
    totalPoints: 0,
    scores: [],
    visitor: loadTeam(data.visitor),
    home: loadTeam(data.home)
  };
  loadScores(game, game.visitor, data.visitor);
  loadScores(game, game.home, data.home);

  return game;
};

const loadTeam = (data: any) => {
  const team: Team = { name: data.name };
  return team;
};

const loadScores = (game: Game, team: Team, data: any) => {
  if (data.score !== "") {
    const score: FinalScore = {
      game: game,
      team: team,
      score: parseInt(data.score)
    };
    game.scores.push(score);
  }
}

const loadPick = (data: any, games: Map<string, Game>) => {
  const game = games.get(data.game_name) || unknownGame();
  const pick: Pick = {
    game: game,
    team: data.team_name === game.home.name ? game.home : game.visitor,
    points: parseInt(data.points)
  }

  return pick;
}

const loadParticipant = (data: any, games: Map<string, Game>) => {
  const participant: Participant = {
    name: data.name,
    tieBreaker: parseInt(data.tie_breaker),
    picks: data.picks.map((pick: any) => loadPick(pick, games))
  };

  return participant;
};

const reconcile = (games: Array<Game>, participants: Array<Participant>) => {
  games.forEach(game => {
    const allPicks = participants.flatMap(p => p.picks);
    const gamePicks = allPicks.filter(pick => pick.game === game);
    game.totalPoints = gamePicks.reduce((acc, cur) => acc + cur.points, 0);
    if (isCompleted(game)) {
      const winning = winner(game);
      console.log(`Reconciling for winning team ${winning && winning.name}`);
      game.totalPointsWon = gamePicks.reduce((acc, cur) => acc + (cur.team === winning ? cur.points : 0), 0);
    }
  });
}

export const isCompleted = (game: Game) => {
  return scoreForTeam(game, game.visitor) && scoreForTeam(game, game.home);
};

export const scoreForTeam = (game: Game, targetTeam: Team) => {
  const scores = game.scores.filter(score => score.team === targetTeam);
  if (scores.length === 0) {
    return undefined;
  } else {
    return scores[0].score;
  }
};

// TODO: turn into a game result (win, loss, tie, etc)?
export const winner = (game: Game) => {
  if (!isCompleted(game)) {
    return undefined;
  }
  const visitorScore = scoreForTeam(game, game.visitor);
  const homeScore = scoreForTeam(game, game.home);

  if (visitorScore && homeScore && visitorScore > homeScore) {
    return game.visitor;
  } else if (visitorScore && homeScore && homeScore > visitorScore) {
    return game.home;
  } else {
    return undefined;
  }
};


/*export interface GameData {
  name: string;
  location: string;
  time: string;
  visitor: TeamWithScore;
  home: TeamWithScore;
  completed(): boolean;
  winner(): string | undefined;
};

class GameDataImpl implements GameData {
  constructor(readonly name: string, readonly location: string, readonly time: string, readonly visitor: TeamWithScore, readonly home: TeamWithScore) { }

  completed(): boolean {
    return this.visitor.score !== undefined && this.home.score !== undefined;
  }

  winner(): string | undefined {
    if (this.visitor.score !== undefined && this.home.score !== undefined) {
      if (this.visitor.score > this.home.score) {
        return this.visitor.name;
      } else if (this.home.score > this.visitor.score) {
        return this.home.name;
      }
    }

    return undefined;
  }
}

const unknownGame = () => {
  return {} as GameData;
}

const loadGameData = (data: any) => {
  return new GameDataImpl(
    data.name,
    data.location,
    data.time,
    loadTeamWithScore(data.visitor),
    loadTeamWithScore(data.home)
  );
};

export interface Pick {
  game: GameData;
  team: string;
  points: number;
};

const loadPick = (data: any, games: Map<string, GameData>) => {
  const pick: Pick = {
    game: games.get(data.game_name) || unknownGame(),
    team: data.team_name,
    points: parseInt(data.points)
  }

  return pick;
}

export interface Participant {
  name: string;
  tieBreaker: number;
  picks: Array<Pick>;
};

const loadParticipant = (data: any, games: Map<string, GameData>) => {
  const participant: Participant = {
    name: data.name,
    tieBreaker: parseInt(data.tie_breaker),
    picks: data.picks.map((pick: any) => loadPick(pick, games))
  };

  return participant;
};

export interface Data {
  games: Array<GameData>;
  participants: Array<Participant>;
}

// TODO: this should be attached to GameData
export interface GameStats {
  medianPoints: number;
  medianTeam: string;
  totalPoints: number;
  totalPointsRank: number;
  totalPointsWon?: number;
  totalPointsWonRank?: number;
}
*/

// export const computeGameStats = (data: Data, game: Game) => {
//   const allPicks = data.participants.flatMap(p => p.picks).filter(p => p.game === game);
//   const total = allPicks.reduce((acc, cur) => acc + cur.points, 0);
//   const median = medianPickForGame(data, game);

//   if (isCompleted(game)) {
//     const totalWon = allPicks.filter(pick => pick.team === winner(game)).map(pick => pick.points).reduce((acc, cur) => acc + cur, 0);
//   }
// };

export const averagePickForGame = (data: Data, game: Game) => {
  const allPicks = data.participants.flatMap(p => p.picks).filter(p => p.game === game);
  const sum = allPicks.reduce((acc, cur) => acc + (cur.team === game.visitor ? -cur.points : cur.points), 0);
  const avg = sum / allPicks.length;
  if (avg < 0) {
    return { team: game.visitor.name, points: -avg.toFixed(2) };
  } else {
    return { team: game.home.name, points: avg.toFixed(2) };
  }
};

export const medianPickForGame = (data: Data, game: Game) => {
  const allPicks = data.participants.flatMap(p => p.picks).filter(p => p.game === game);
  const sortedPoints = allPicks.map(pick => pick.team === game.visitor ? -pick.points : pick.points).sort((x, y) => x - y);
  const medianPoints = sortedPoints[Math.floor(sortedPoints.length / 2)];
  if (medianPoints < 0) {
    return { team: game.visitor.name, points: -medianPoints };
  } else {
    return { team: game.home.name, points: medianPoints };
  }
};

const queryClient = new QueryClient();

const fetchResults = async () => {
  const res1 = Promise.all([
    fetch("http://localhost:5000/results.json"),
    fetch("http://localhost:5000/participants.json")
  ]).then(([r1, r2]) => [r1.json(), r2.json()])
    .then(async ([a, b]) => {
      const games: Array<Game> = (await a).map(loadGame);
      const gamesMap = new Map<string, Game>();
      games.forEach(game => gamesMap.set(game.name, game));
      const participants: Array<Participant> = (await b).map((participant: any) => loadParticipant(participant, gamesMap));
      reconcile(games, participants);
      const data: Data = { games: games, participants: participants };

      return data;
    });

  return res1;
};

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Shell />
    </QueryClientProvider>
  );
}

function Shell() {
  const { data, isLoading, status } = useQuery("results", fetchResults);

  // useEffect(() => {
  //   Promise.all([
  //     fetch("https://danhodge-cfb.s3.amazonaws.com/2022/participants_2022.json"),
  //     fetch("https://danhodge-cfb.s3.amazonaws.com/2022/results_2022.json"),
  //   ]).then(([p, r]) => {
  //     let x = p.json() as Promise<{ str: "" }>;
  //     setParticipants(p.json() as Promise<{ str: "" });
  //     setResults(r.json());
  //   });
  // });

  const game = data && data.games[2];

  return isLoading ?
    <div className="App">Loading...</div> :
    (game ?
      <div>
        <div><GameComponent data={data} game={game} /></div>
      </div> : <div>?</div>);
}

export default App;
