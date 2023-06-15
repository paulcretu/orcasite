defmodule Orcasite.Notifications do
  use Ash.Api, extensions: [AshAdmin.Api]

  resources do
    registry Orcasite.Notifications.Registry
  end

  admin do
    show? true
  end
end