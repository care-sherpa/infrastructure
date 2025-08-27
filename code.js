const taskGroups = {};

$input.all().forEach((item) => {
  item.json["User"].forEach((user) => {
    const email = user.email || "no-email@example.com";
    const userName = user.name;

    if (!taskGroups[email]) {
      taskGroups[email] = {
        userName: userName,
        companyGroups: {},
      };
    }

    const companyName = item.json["Customer Name"]?.[0] || "Unknown Company";
    if (!taskGroups[email].companyGroups[companyName])
      taskGroups[email].companyGroups[companyName] = [];
    taskGroups[email].companyGroups[companyName].push(item.json);
  });
});

return Object.entries(taskGroups).map(([email, userData]) => {
  const allTables = Object.entries(userData.companyGroups)
    .map(([companyName, tasks]) => {
      // Deduplicate tasks by ID
      const uniqueTasks = [];
      const seenIds = new Set();
      for (const t of tasks) {
        if (!seenIds.has(t.id)) {
          uniqueTasks.push(t);
          seenIds.add(t.id);
        }
      }
      const sortedData = uniqueTasks.sort((a, b) => {
        // Sort by due date (no dates go to bottom)
        const dateA = a["Due Date"]
          ? new Date(a["Due Date"])
          : new Date("9999-12-31");
        const dateB = b["Due Date"]
          ? new Date(b["Due Date"])
          : new Date("9999-12-31");
        return dateA - dateB;
      });

      const rows = sortedData
        .map((t) => {
          const dueDate = t["Due Date"] ? new Date(t["Due Date"]) : null;
          let backgroundColor = "#f8f9fa"; // default

          if (!dueDate) {
            backgroundColor = "#f8f9fa";
          } else {
            const now = $now;
            const sevenDaysFromNow = new Date(now + 7 * 24 * 60 * 60 * 1000);

            if (dueDate < now) {
              backgroundColor = "#ffebee"; // softer red
            } else if (dueDate <= sevenDaysFromNow) {
              backgroundColor = "#fff3e0"; // softer orange
            } else {
              backgroundColor = "#e8f5e8"; // softer green
            }
          }

          return `<tr style="background-color:${backgroundColor}; border-bottom: 1px solid #dee2e6;"><td style="padding: 12px; border-right: 1px solid #dee2e6;">${
            getPriorityEmoji(t["Priority"]) + " " + t["Task Name"]
          }</td><td style="padding: 12px; border-right: 1px solid #dee2e6;">${
            t["Due Date"] ? t["Due Date"] : "N/A"
          }</td><td style="padding: 12px;">${t["Status"]}</td></tr>`;
        })
        .join("");

      const htmlTable = `<h3 style="margin: 20px 0 10px 0; color: #333; font-family: Arial, sans-serif;">Tasks for ${companyName}</h3><table style="border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; margin: 0 0 30px 0; border: 1px solid #dee2e6;"><tr style="background-color: #f8f9fa; font-weight: bold;"><th style="padding: 12px; text-align: left; border-right: 1px solid #dee2e6; border-bottom: 2px solid #dee2e6;">Task</th><th style="padding: 12px; text-align: left; border-right: 1px solid #dee2e6; border-bottom: 2px solid #dee2e6;">Due Date</th><th style="padding: 12px; text-align: left; border-bottom: 2px solid #dee2e6;">Status</th></tr>${rows}</table>`;

      return htmlTable;
    })
    .join("");

  return {
    json: {
      email,
      userName: userData.userName,
      html: allTables,
    },
  };
});

function getPriorityEmoji(priority) {
  if (!priority) return "";

  const priorityStr = priority.toString().toLowerCase();
  if (priorityStr.includes("high") || priorityStr.includes("1")) {
    return '<span title="High Priority">🔴</span>';
  } else if (priorityStr.includes("medium") || priorityStr.includes("2")) {
    return '<span title="Medium Priority">🟡</span>';
  } else if (priorityStr.includes("low") || priorityStr.includes("3")) {
    return '<span title="Low Priority">🟢</span>';
  }
  return "";
}
