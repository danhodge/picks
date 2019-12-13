function teamClickListener() {
  return (event) => {
    if (event.target.classList.contains("chosen")) {
      // no-op
    } else if (event.target.classList.contains("not-chosen")) {
      selectTeam(event.target);
    } else {
      console.log("Error: class list does not include chosen or not-chosen: " + event.target.classList);
    }
  };
}

function selectTeam(teamElement) {
  let row = teamElement.parentElement;
  for (let td of row.children) {
    if (td.classList.contains("team-name") && td != teamElement) {
      td.classList.remove("chosen");
      td.classList.add("not-chosen");
      break;
    }
  }

  teamElement.classList.remove("not-chosen");
  teamElement.classList.add("chosen");

  let choice = Array.from(row.getElementsByTagName("input")).find((elem) => elem.type == "hidden");
  if (choice != null) {
    choice.value = teamElement.dataset.teamId;
  } else {
    console.log("Error: Unable to update choice");
  }
}
