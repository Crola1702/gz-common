/*
 * Copyright (C) 2022 Open Source Robotics Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#ifndef GZ_COMMON__CONFIG_HH_
#define GZ_COMMON__CONFIG_HH_

#include <ignition/common/config.hh>

/* Version number */
#define GZ_COMMON_MAJOR_VERSION IGNITION_COMMON_MAJOR_VERSION
#define GZ_COMMON_MINOR_VERSION IGNITION_COMMON_MINOR_VERSION
#define GZ_COMMON_PATCH_VERSION IGNITION_COMMON_PATCH_VERSION

#define GZ_COMMON_VERSION IGNITION_COMMON_VERSION
#define GZ_COMMON_VERSION_FULL IGNITION_COMMON_VERSION_FULL

#define GZ_COMMON_VERSION_HEADER IGNITION_COMMON_VERSION_HEADER

/* #undef HAVE_AVDEVICE */

namespace ignition
{
}

namespace gz
{
  using namespace ignition;
}

#endif
