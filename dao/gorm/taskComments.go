package gorm

import (
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
)

func (t Task) GetCommentsByTask(taskId int) ([]model.Comment, error) {
	var comments []model.Comment

	commentsFromDB, err := t.db.Table(fmt.Sprintf(`%s tc`, new(model.Task).CommentsTableName())).
		Select(`tc.id, tc.staff_id, ts.login, tc.task_id, tc."text", tc.created_at, tc.deleted_at`).
		Joins("join tasks.staff ts on (ts.id = tc.staff_id)").
		Where(`tc.task_id = ?`, taskId).
		Rows()

	if err != nil {
		return nil, err
	}

	for commentsFromDB.Next() {
		var comment model.Comment
		err := commentsFromDB.Scan(&comment)
		if err != nil {
			return nil, err
		}
		comments = append(comments, comment)
	}

	return comments, nil
}
