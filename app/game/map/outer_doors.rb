module GameMap
  def outer_door_cell?(floor, tx, ty)
    @outer_door_cells && @outer_door_cells[[floor, tx, ty]]
  end
end
