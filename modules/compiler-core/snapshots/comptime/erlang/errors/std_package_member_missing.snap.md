----- SOURCE CODE
import {bool} from "std";

fn main() {
    val x = bool.collapse(true);
}

----- ERROR
error: this "std" module has no such public function
  ┌─ :4:18
  │
4 │     val x = bool.collapse(true);
  │                  ^

  hint: Check the function name against the module's exports.
