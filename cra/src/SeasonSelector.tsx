import { Season } from "./App";

export interface SeasonSelectorProps {
  seasons: Array<Season>;
  setSeason: (s: string) => void;
  selected?: Season;
}

export const SeasonSelector = (props: SeasonSelectorProps) => {
  const opts = props.seasons.map((season) => {
    return props.selected?.path === season.path ?
      <option key={"season_" + season.path} value={season.path} selected>{season.name}</option> :
      <option key={"season_" + season.path} value={season.path}>{season.name}</option>;
  });

  return <select onChange={(e) => props.setSeason(e.target.value)}>{opts}</select>
};