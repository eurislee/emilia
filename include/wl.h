/**
 * WindowWl - window interface implementation for wayland
 */

#ifndef NOWL

#pragma once

#include "window.h"
#include "util.h"

struct WindowBase* Window_new_wayland(Pair_uint32_t res, Pair_uint32_t cell_dims);

#endif
