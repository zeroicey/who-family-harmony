@Component
export struct AppIcon {
  @Prop name: string = 'placeholder';
  @Prop iconSize: number = 24;
  @Prop radius: number = 0;

  private iconResource(): Resource {
    if (this.name === 'tab_home') {
      return $r('app.media.icon_tab_home');
    }
    if (this.name === 'tab_community') {
      return $r('app.media.icon_tab_community');
    }
    if (this.name === 'tab_helper') {
      return $r('app.media.icon_tab_helper');
    }
    if (this.name === 'tab_knowledge') {
      return $r('app.media.icon_tab_knowledge');
    }
    if (this.name === 'tab_me') {
      return $r('app.media.icon_tab_me');
    }
    if (this.name === 'tab_recruit') {
      return $r('app.media.icon_tab_recruit');
    }
    if (this.name === 'tab_service') {
      return $r('app.media.icon_tab_service');
    }
    if (this.name === 'ai') {
      return $r('app.media.icon_ai');
    }
    if (this.name === 'chat') {
      return $r('app.media.icon_chat');
    }
    if (this.name === 'learn') {
      return $r('app.media.icon_learn');
    }
    if (this.name === 'logo') {
      return $r('app.media.icon_logo');
    }
    if (this.name === 'community_comment') {
      return $r('app.media.icon_community_comment');
    }
    if (this.name === 'community_dynamic') {
      return $r('app.media.icon_community_dynamic');
    }
    if (this.name === 'community_errand') {
      return $r('app.media.icon_community_errand');
    }
    if (this.name === 'community_like') {
      return $r('app.media.icon_community_like');
    }
    if (this.name === 'community_liked') {
      return $r('app.media.icon_community_liked');
    }
    if (this.name === 'community_rating') {
      return $r('app.media.icon_community_rating');
    }
    if (this.name === 'community_secondhand') {
      return $r('app.media.icon_community_secondhand');
    }
    if (this.name === 'community_position') {
      return $r('app.media.icon_community_position');
    }
    if (this.name === 'community_yuan') {
      return $r('app.media.icon_community_yuan');
    }
    if (this.name === 'community_more') {
      return $r('app.media.icon_community_more');
    }
    if (this.name === 'community_trash') {
      return $r('app.media.icon_community_trash');
    }
    if (this.name === 'community_view') {
      return $r('app.media.icon_community_view');
    }
    if (this.name === 'me_about') {
      return $r('app.media.icon_me_about');
    }
    if (this.name === 'me_address') {
      return $r('app.media.icon_me_address');
    }
    if (this.name === 'me_feedback') {
      return $r('app.media.icon_me_feedback');
    }
    if (this.name === 'me_focus') {
      return $r('app.media.icon_me_focus');
    }
    if (this.name === 'me_message') {
      return $r('app.media.icon_me_message');
    }
    if (this.name === 'me_order') {
      return $r('app.media.icon_me_order');
    }
    if (this.name === 'me_task') {
      return $r('app.media.icon_me_task');
    }
    if (this.name === 'profile_bio') {
      return $r('app.media.icon_profile_bio');
    }
    if (this.name === 'profile_gender') {
      return $r('app.media.icon_profile_gender');
    }
    if (this.name === 'profile_grade') {
      return $r('app.media.icon_profile_grade');
    }
    if (this.name === 'profile_major') {
      return $r('app.media.icon_profile_major');
    }
    if (this.name === 'profile_name') {
      return $r('app.media.icon_profile_name');
    }
    if (this.name === 'profile_phone') {
      return $r('app.media.icon_profile_phone');
    }
    if (this.name === 'profile_publish') {
      return $r('app.media.icon_profile_publish');
    }
    if (this.name === 'profile_school') {
      return $r('app.media.icon_profile_school');
    }
    return $r('app.media.icon_placeholder');
  }

  build() {
    Image(this.iconResource())
      .width(this.iconSize)
      .height(this.iconSize)
      .borderRadius(this.radius)
      .objectFit(ImageFit.Contain)
  }
}
