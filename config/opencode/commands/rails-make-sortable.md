---
agent: build
description: Makes a given model sortable
---
# Make model $1 sortable, with an optional scope of $2.

## Prerequisites:
- The `acts_as_list` gem
- Route concern - This should be added to `config/routes.rb`, unless already present:
  ```ruby
  concern :sortable do
    member do
      post :update_position
    end
  end
  ```
- Look for `app/models/concerns/*/sortable.rb`
  - If it doesn't exist, inform the user and STOP HERE.
- Look for `app/assets/javascripts/backend/sortable.js`
  - If it doesn't exist, inform the user and STOP HERE.

## Behaviour
- When looking for patterns in other files, stop at maximum three files.

## Implementation steps:
- Look if the model in question has a `position` column. If it doesn't, create a migration to add it. Make sure to replace the placeholders currently in `<>` brackets:
  ```ruby
  class AddPositionTo<$1> < ActiveRecord::Migration[8.1]
    def change
      add_column :<MODEL_TABLE_NAME>, :position, :integer, after: <COLUMN_BEFORE_CREATED_AT>

      reversible do |dir|
        dir.up do
          execute <<~SQL
          UPDATE <MODEL_TABLE_NAME> AS t
          JOIN (
          SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
          FROM <MODEL_TABLE_NAME>
          ) AS ranked ON t.id = ranked.id
          SET t.position = ranked.rn
          SQL
        end
      end
    end
  end
  ```
- Include the sortable concern in the model. If the file already has includes, add it to the bottom of the list
  - If $2 was passed in, make sure to apply the sortable scope to the model
- In `spec/support`, look for a file named `<APPLICATION_NAME_IN_SNAKECASE>/sortable.rb`. If it exists:
  - Look for the model's spec file in `spec/models/<MODEL_NAME_IN_SNAKECASE>_spec.rb`, and if it exists add `it_behaves_like 'sortable'`
  - If there are multiple `it_behaves_like`, make sure to add it to the bottom of that list
- In the model's main `Backend` controller, add a `before_action` to run `update_position`
  - If there are multiple `before_action` defined, add it to the bottom of that list
  - If there are multiple `before_action` defined by means of an array, add `update_position` to the array
- In the model's main `Backend` controller, add the `update_position` method.
  - This is what will be called when the user initiates a repositioning of a model record via the backend
  - Note how model is called within the controller (usually `@model`)
  - The typical variation of the `update_position` method is this one:
    ```ruby
    def update_position
      @model.set_position(params[:position])
      render body: nil
    end
    ```
  - Depending at what level of namespacing we are and what model record needs positioning, the body of that method may need to be adjusted.
  - In the views for the controller:
    - Look for the main overview `<table>` element
    - Add a `<tbody>` if it doesn't already exist
    - Add a data attribute with the route to the new `update_position` action. Typically something like `data-update-position="<%= update_position_backend_<CORRECT_MODEL_ROUTE_PATH>_path(<MODEL_INSTANCE>) %>"`
