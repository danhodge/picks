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

  return <select className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" onChange={(e) => props.setSeason(e.target.value)}>{opts}</select>
};